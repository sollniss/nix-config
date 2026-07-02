{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = 80;
  network = config.prefs.network;
  vpn = network.subnets.vpn;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  # Friendly name for LAN and VPN clients, resolved by the dnscrypt-proxy
  # cloaking rule below.
  domain = "calendar.pi";

  # Collect CIDRs from all defined subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  cidrCsv = builtins.concatStringsSep ", " subnetCidrs;

  # IPv6 subnets for firewall rules.
  ipv6Allowed = [
    "::1/128"
    "fe80::/10"
  ]
  ++ lib.optional (vpn.cidr6 != null) vpn.cidr6;
  ipv6Csv = builtins.concatStringsSep ", " ipv6Allowed;

  # SOGo talks to PostgreSQL over the unix socket.
  db = "postgresql://sogo@%2Frun%2Fpostgresql/sogo";

  psql = "${config.services.postgresql.package}/bin/psql";

  # Accounts, managed entirely by this config. The login form rejects
  # empty passwords (the backend would accept them), so the password
  # is the username — acceptable on a LAN/VPN-only service.
  users = [
    "d"
    "m"
  ];
  uidCsv = lib.concatMapStringsSep ", " (u: "'${u}'") users;
  userRows = lib.concatMapStringsSep "\n" (u: ''
    INSERT INTO sogo_users VALUES ('${u}', '${u}', '${u}', '${u}', '${u}@localhost')
      ON CONFLICT (c_uid) DO UPDATE SET c_name = EXCLUDED.c_name,
        c_password = EXCLUDED.c_password, c_cn = EXCLUDED.c_cn, mail = EXCLUDED.mail;'') users;

  # Cross-subscribe every user to every other user's personal calendar so it
  # shows up in their calendar list without manual sharing.
  #
  # A user's Calendar/personal folder only exists once they have logged in at
  # least once (nothing seeds it earlier — the tool's claimed auto-create does
  # not happen here). Running "subscribe" against a missing *owner* folder
  # aborts the tool (SIGABRT), and a missing *subscriber* folder means the
  # subscription silently fails to persist. So only subscribe a pair once both
  # folders exist; the timer below re-runs until then, converging as users log
  # in for the first time.
  folderExists =
    u:
    "[ \"$(${psql} -tAX -d sogo -c \"SELECT 1 FROM sogo_folder_info WHERE c_path = '/Users/${u}/Calendar/personal'\")\" = 1 ]";
  subscribeCmds = lib.concatMapStringsSep "\n" (
    owner:
    lib.concatMapStringsSep "\n" (subscriber: ''
      if ${folderExists owner} && ${folderExists subscriber}; then
        sogo-tool manage-acl subscribe '${owner}' Calendar/personal '${subscriber}'
      fi'') (lib.filter (u: u != owner) users)
  ) users;

  # The first time a subscription is shown, SOGo snapshots its label into the
  # subscriber's settings (FolderDisplayNames), and that snapshot then shadows
  # SOGoSubscriptionFolderFormat forever. Clearing it lets the format above
  # (%{UserName}) apply live, so a subscribed calendar always shows its owner's
  # login rather than a stale "Personal Calendar" captured at subscribe time.
  clearSubscriptionNames = pkgs.writeText "sogo-clear-subscription-names.sql" (
    lib.concatMapStringsSep "\n" (u: ''
      UPDATE sogo_user_profile
        SET c_settings = ((c_settings::jsonb) #- '{Calendar,FolderDisplayNames}')::text
        WHERE c_uid = '${u}' AND c_settings IS NOT NULL;
    '') users
  );

  # SOGo creates all of its OCS tables on demand, but the table it
  # authenticates against must exist before login works.
  usersTable = pkgs.writeText "sogo-users.sql" ''
    CREATE TABLE IF NOT EXISTS sogo_users (
      c_uid      VARCHAR(128) NOT NULL PRIMARY KEY,
      c_name     VARCHAR(128) NOT NULL,
      c_password VARCHAR(256) NOT NULL,
      c_cn       VARCHAR(128),
      mail       VARCHAR(256)
    );
    DELETE FROM sogo_users WHERE c_uid NOT IN (${uidCsv});
    ${userRows}
  '';
in
{
  config = lib.mkIf config.prefs.hosted.calendar.enable {
    services.sogo = {
      enable = true;
      vhostName = hostname;
      timezone = config.time.timeZone;
      extraConfig = ''
        WOWorkersCount = 2;
        SOGoMemcachedHost = "127.0.0.1";

        // Calendar and tasks only. Tasks live inside the Calendar
        // module; Mail is hidden by a constraint no user row matches.
        // The Contacts module cannot be disabled, but with
        // isAddressBook = NO it only holds each user's personal book.
        SOGoLoginModule = Calendar;

        // No MTA on this host: never try to send invitations or alarms.
        SOGoAppointmentSendEMailNotifications = NO;
        SOGoACLsSendEMailNotifications = NO;
        SOGoFoldersSendEMailNotifications = NO;
        SOGoEnableEMailAlarms = NO;

        // Every authenticated user (i.e. the other account) may read
        // all events in everyone's calendars; the subscription itself
        // is seeded by the sogo-shared-calendars service below.
        SOGoCalendarDefaultRoles = (
          "PublicViewer",
          "ConfidentialViewer",
          "PrivateViewer"
        );

        // Label a subscribed calendar with its owner's login instead of the
        // default "Personal Calendar (user <mail>)". %{UserName} resolves to
        // the owner's cn (which we set to the uid) from the SQL user source,
        // so it is stable and, unlike %{FolderName}, not subject to SOGo's
        // stale folder-name cache after a rename.
        SOGoSubscriptionFolderFormat = "%{UserName}";

        SOGoUserSources = (
          {
            type = sql;
            id = users;
            viewURL = "${db}/sogo_users";
            canAuthenticate = YES;
            isAddressBook = NO;
            userPasswordAlgorithm = "plain";
            ModulesConstraints = {
              Mail = { c_uid = "_mail_disabled_"; };
            };
          }
        );

        SOGoProfileURL = "${db}/sogo_user_profile";
        OCSFolderInfoURL = "${db}/sogo_folder_info";
        OCSSessionsFolderURL = "${db}/sogo_sessions_folder";
        OCSStoreURL = "${db}/sogo_store";
        OCSAclURL = "${db}/sogo_acl";
        OCSCacheFolderURL = "${db}/sogo_cache_folder";
      '';
    };

    # The upstream module writes /etc/sogo/sogo.conf at boot via the sogo
    # ExecStartPre, which fails under our read-only /etc overlay. That step
    # only exists to substitute configReplaces secrets, which we don't use.
    environment.etc."sogo/sogo.conf".text = config.environment.etc."sogo/sogo.conf.raw".text;
    systemd.services.sogo.serviceConfig.ExecStartPre = lib.mkForce [ ];

    # Email alarms are disabled above, so the minutely notifier is useless.
    systemd.services.sogo-ealarms.startAt = lib.mkForce [ ];

    services.memcached.enable = true;

    services.postgresql = {
      enable = true;
      # No TCP listener; SOGo connects over the unix socket only.
      settings.listen_addresses = lib.mkForce "";
      ensureDatabases = [ "sogo" ];
      ensureUsers = [
        {
          name = "sogo";
          ensureDBOwnership = true;
        }
      ];
    };

    systemd.services.sogo-users-table = {
      description = "SOGo users table setup";
      after = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      requires = [
        "postgresql.service"
        "postgresql-setup.service"
      ];
      before = [ "sogo.service" ];
      requiredBy = [ "sogo.service" ];
      serviceConfig = {
        Type = "oneshot";
        # Stay "active (exited)" so nixos-rebuild switch re-runs this whenever
        # the user list changes: a plain oneshot goes inactive after its first
        # run and switch never restarts it, leaving stale rows in sogo_users.
        RemainAfterExit = true;
        User = "sogo";
        Group = "sogo";
      };
      script = ''
        ${psql} -v ON_ERROR_STOP=1 -d sogo -f ${usersTable}
      '';
    };

    # sogo-tool reads /etc/sogo/sogo.conf (now shipped statically) for the
    # DB URLs; ordering after sogo.service just ensures PostgreSQL is up.
    #
    # This is fully idempotent and runs on a timer (startAt) so it converges
    # instead of depending on boot ordering: cross-subscription only takes
    # effect once each user's Calendar/personal folder exists, which happens on
    # that user's first web login. Re-asserting periodically picks that up
    # without a rebuild, and reverts manual changes, keeping it declarative.
    systemd.services.sogo-shared-calendars = {
      description = "SOGo cross-user calendar subscriptions";
      after = [
        "sogo.service"
        "memcached.service"
      ];
      requires = [ "sogo.service" ];
      wantedBy = [ "multi-user.target" ];
      startAt = [ "*:0/15" ];
      path = [ pkgs.sogo ];
      serviceConfig = {
        Type = "oneshot";
        User = "sogo";
        Group = "sogo";
      };
      # Subscribe, then clear the label snapshots so the %{UserName} format
      # applies live instead of a stale name captured at subscribe time.
      script = ''
        ${subscribeCmds}
        ${psql} -v ON_ERROR_STOP=1 -d sogo -f ${clearSubscriptionNames}
      '';
    };

    # The upstream module proxies sogod through nginx but leaves nginx
    # itself off and redirects / to an absolute https URL. This host
    # serves plain HTTP on the LAN, so rewrite relative to the vhost.
    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      virtualHosts.${hostname} = {
        default = true; # Accept requests by IP as well as by hostname.
        serverAliases = [ domain ];
        locations."/".extraConfig = lib.mkForce ''
          rewrite ^ /SOGo;
          allow all;
        '';
        locations."/principals/".extraConfig = lib.mkForce ''
          rewrite ^ /SOGo/dav;
          allow all;
        '';
      };
    };

    # Resolve ${domain} to this host for every client using the local
    # dnscrypt-proxy resolver (LAN clients and WireGuard peers alike).
    # Cloaking answers before the block_undelegated plugin runs, so the
    # made-up TLD works despite block_undelegated = true.
    services.dnscrypt-proxy = lib.mkIf config.prefs.hosted.dns.enable {
      settings.cloaking_rules = toString (
        pkgs.writeText "sogo-cloaking-rules.txt" ''
          ${domain} ${self.ip}
        ''
      );
    };

    # Only allow HTTP access from known subnets (LAN + VPN).
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${cidrCsv} } tcp dport ${toString port} accept
      ip6 saddr { ${ipv6Csv} } tcp dport ${toString port} accept
      tcp dport ${toString port} drop
    '';
  };
}
