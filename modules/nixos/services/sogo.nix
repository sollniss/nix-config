{
  config,
  lib,
  pkgs,
  ...
}:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "calendar.pi";

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
  # least once. So only subscribe a pair once both folders exist.
  # The timer below re-runs until then, converging as users log in for the first time.
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

  # A new event gets no sensible default length, and SOGo has no setting for
  # it, so patch the (minified) frontend bundle nginx serves straight from the
  # store (see the vhost below):
  #
  # 1. adjustAllDay(): unchecking "All day" spans the event across the whole
  #    business day (SOGoDayStartTime..SOGoDayEndTime). That length then
  #    sticks, because editing the start time preserves the duration, so a
  #    15:00 start pushes the end past midnight. Make it one hour long.
  #
  # 2. onDoubleClick(): every event created by double-clicking the grid starts
  #    out as an all-day event, in every view. Make it a one-hour event instead
  #    (4 quarters = 1 hour). On an hour cell of the day/week view it starts at
  #    the double-clicked time — the pointer handler already knows how to map a
  #    click to a quarter-hour, that machinery just isn't used on this path.
  #    The month view and the all-day row have no hour to read, so those fall
  #    back to the start of the business day, like SOGo does when turning an
  #    all-day event into a timed one.
  #
  # Both replacements are literal --replace-fail, so a SOGo update that touches
  # this code fails the build instead of silently shipping an unpatched file,
  # and node then checks the result still parses.
  schedulerJs = pkgs.runCommand "sogo-scheduler-1h-events.js" { } ''
    cp ${pkgs.sogo}/lib/GNUstep/SOGo/WebServerResources/js/Scheduler.services.js $out
    chmod +w $out
    substituteInPlace $out \
      --replace-fail \
        'this.component.end.setHours(w),this.component.end.setMinutes(0)' \
        'this.component.end.setTime(this.component.start.getTime()+36e5)' \
      --replace-fail \
        'isAllDay:1};(n={component:new y(n),dayNumber:s.dayNumber,length:0}).component.blocks=[n],(t=new d("double-click")).initFromBlock(n),t.currentEventCoordinates.duration=0,' \
        'isAllDay:0};(n={component:new y(n),dayNumber:s.dayNumber,length:0}).component.blocks=[n],(t=new d("double-click")).initFromBlock(n),t.currentEventCoordinates.duration=4,(function(q){q?t.setTimeFromQuarters(n.component.start,q.y):n.component.start.setHours(parseInt(m.defaults.SOGoDayStartTime),0)})(r.hasClass("clickableHourCell")&&f.$view?(t.prepareWithEventType("multiday"),t.initFromEvent(e),t.getEventViewCoordinates(f.$view)):null),'
    ${lib.getExe pkgs.nodejs} --check $out
  '';

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
  # nginx hardening and the LAN/VPN-only firewall rules for port 80.
  imports = [ ./nginx.nix ];

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
        // The Contacts module cannot be disabled.
        SOGoLoginModule = Calendar;

        // No MTA on this host: never try to send invitations or alarms.
        SOGoAppointmentSendEMailNotifications = NO;
        SOGoACLsSendEMailNotifications = NO;
        SOGoFoldersSendEMailNotifications = NO;
        SOGoEnableEMailAlarms = NO;

        // Our logins are a single character, and the default of 2 means the
        // attendee autocomplete never fires for them (it is the md-min-length
        // of the search field, and also gates the lookup server side).
        SOGoSearchMinimumWordLength = 1;

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
            displayName = "Users";
            viewURL = "${db}/sogo_users";
            canAuthenticate = YES;
            // Required for the attendee autocomplete to find the accounts: it
            // searches the Contacts subfolders (Contacts/allContactSearch),
            // and a user source only becomes one of those when it is exposed
            // as an address book. The cost is that "Users" shows up as a
            // read-only address book next to each user's personal one.
            isAddressBook = YES;
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
      virtualHosts.${hostname} = {
        default = true; # Accept requests by IP as well as by hostname.
        serverAliases = [ domain ];
        locations."/".extraConfig = lib.mkForce ''
          rewrite ^ /SOGo;
        '';
        locations."/principals/".extraConfig = lib.mkForce ''
          rewrite ^ /SOGo/dav;
        '';

        # The upstream module writes an "allow all" into these two, which would
        # shadow the http-level allowlist, so restate them without it.
        # The alias is upstream's, verbatim.
        locations."/SOGo.woa/WebServerResources/".extraConfig = lib.mkForce ''
          alias ${pkgs.sogo}/lib/GNUstep/SOGo/WebServerResources/;
        '';
        locations."/SOGo/WebServerResources/".extraConfig = lib.mkForce ''
          alias ${pkgs.sogo}/lib/GNUstep/SOGo/WebServerResources/;
        '';

        # The upstream module serves WebServerResources straight from the
        # store, so the patch above only needs to shadow a single file.
        # Exact-match locations win over the module's prefix aliases; SOGo
        # requests the bundle under both prefixes.
        locations."= /SOGo.woa/WebServerResources/js/Scheduler.services.js".alias = schedulerJs;
        locations."= /SOGo/WebServerResources/js/Scheduler.services.js".alias = schedulerJs;
      };
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
