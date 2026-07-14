# Samba: one shared folder, exported over SMB3 to the LAN and the VPN.
#
# Deliberately a single share with a single account: everyone who can log in
# sees and edits everything, and every file lands owned by the same user (see
# `force user` below). There is no per-user granularity to get wrong.
#
# The account exists only to hold a Samba password. It is a system user with no
# shell and a locked unix password, so the credential buys files and nothing
# else: no shell, no sudo (this host has none anyway), no SSH. That matters here
# because Samba's passdb stores an unsalted MD4 hash, which is password
# equivalent and cracks instantly if it ever leaks. The password must therefore
# be long, random, and used nowhere else. It is read from a secret file, not
# from the store; see prefs.secrets.sambaPassword.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prefs.hosted.share;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "nas.pi";
  port = 445;

  user = "smbshare";
  group = "smbshare";
  passwordPath = config.prefs.secrets.sambaPassword;

  # The WireGuard interface, as named in ./wireguard.nix.
  wgIface = "wg0";

  subnets = builtins.attrValues network.subnets;
  cidrs = map (s: s.cidr) subnets;
  cidrs6 = builtins.filter (c: c != null) (map (s: s.cidr6) subnets);

  # nftables allow list, as in ./ssh.nix and ./nginx.nix. Both address families
  # are needed: VPN peers hold an address in each, so a v4-only rule would drop
  # every phone that came in over the tunnel.
  cidrCsv = builtins.concatStringsSep ", " cidrs;
  ipv6Csv = builtins.concatStringsSep ", " (
    [
      "::1/128"
      "fe80::/10"
    ]
    ++ cidrs6
  );

  # Samba-level allow list, mirroring those nftables rules. The packet filter
  # already drops anything that is not LAN or VPN, and smbd drops it a second
  # time on its own, so a mistake in one of the two cannot expose 445 on its
  # own. This host is the one that faces the internet (WireGuard on 443, a
  # dynv6 name pointed at it), which is why 445 gets two independent gates
  # rather than one. `hosts allow` takes precedence over `hosts deny`, so this
  # is deny-by-default.
  hostsAllow = [
    "127.0.0.1"
    "::1"
  ]
  ++ cidrs
  ++ cidrs6;

in
{
  config = lib.mkIf cfg.enable {
    services.samba = {
      enable = true;

      # NetBIOS name service: a legacy broadcast protocol that no client here
      # needs, and pure attack surface on the host that also serves the LAN's
      # DNS and DHCP. Windows finds the share by name through the local resolver
      # instead (see the cloaking entry at the bottom). Both this and winbindd
      # default to true upstream, hence the explicit false.
      nmbd.enable = false;
      # Only ever used to join an Active Directory domain.
      winbindd.enable = false;
      # Never let a non-root user publish a share of their own.
      usershares.enable = false;

      # Would open 139/445 tcp and 137/138 udp to everyone. We write the rules
      # ourselves below, as ./ssh.nix and ./nginx.nix do.
      openFirewall = false;

      settings = {
        global = {
          security = "user";
          "server role" = "standalone server";
          workgroup = "WORKGROUP";
          # Default is "Samba %v", which hands out the version to anyone asking.
          "server string" = "";

          # Listen on 445 only, and on nothing but loopback, the LAN and the
          # tunnel. NetBIOS is off, so port 139 never opens.
          "smb ports" = port;
          "disable netbios" = "yes";
          "bind interfaces only" = "yes";
          interfaces = [
            "lo"
            config.prefs.nixos.interface
          ]
          ++ lib.optional config.prefs.hosted.vpn.enable wgIface;
          "hosts allow" = hostsAllow;
          "hosts deny" = "ALL";

          # SMB 3.1.1 and nothing older, so there is no negotiating down to SMB1
          # or to a weaker dialect. Windows 10/11 and the Linux cifs client both
          # speak it natively, so this costs nothing in compatibility.
          "server min protocol" = "SMB3_11";
          "client min protocol" = "SMB3_11";

          # The anti-relay and anti-tamper control, and the one setting here not
          # worth trading away: it is what stops someone already on the LAN from
          # replaying or rewriting an authenticated session. Windows 11 24H2
          # requires signing by default anyway, so the clients agree.
          "server signing" = "required";

          # Confidentiality on top of that, so file contents are encrypted even
          # on the LAN, where nothing else protects them.
          #
          # This one does cost something. The Pi 4's Cortex-A72 ships without the
          # ARMv8 crypto extensions (/proc/cpuinfo lists no `aes`), so AES-GCM
          # here is pure software and will very likely be the throughput ceiling
          # of the share, well under what the link could otherwise carry. VPN
          # clients are already encrypted by WireGuard, which uses ChaCha20
          # precisely because it is fast without AES hardware, so for them this
          # is close to redundant. If a large copy turns out too slow, "desired"
          # is the setting to fall back to: signing stays required either way,
          # and it is signing, not encryption, that protects the credential.
          "smb encrypt" = "required";

          # No LANMAN, no NTLMv1. This is the current upstream default; stating
          # it means a future change of that default cannot quietly weaken us.
          "ntlm auth" = "ntlmv2-only";

          # Nothing is anonymous, and a bad password is a failure rather than a
          # silent downgrade to a guest session.
          "guest ok" = "no";
          "map to guest" = "never";
          "restrict anonymous" = 2;
          "invalid users" = [ "root" ];

          # Clients may write whatever they like into the share, so give them no
          # way to reach out of it. The mount is nosuid,nodev,noexec for the same
          # reason (see the Pi's hardware-configuration.nix).
          "follow symlinks" = "no";
          "wide links" = "no";

          # This host has no printers, and printing is a large slice of Samba's
          # surface that would otherwise be live.
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";

          # Log to the journal rather than to files under /var/log/samba. The
          # journal on this host is volatile (see the Pi's configuration.nix),
          # so this keeps a chatty daemon off the SD card entirely.
          logging = "systemd";
          "log level" = 1;
        };

        share = {
          path = cfg.path;
          comment = "";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "valid users" = [ user ];

          # One pool, one owner. With a single account this is technically
          # redundant, but it is what makes "everyone sees and edits everything"
          # a property of the config rather than an accident of there happening
          # to be only one user, and it stays true if a second account is ever
          # added.
          "force user" = user;
          "force group" = group;
          "create mask" = "0660";
          "force create mode" = "0660";
          "directory mask" = "2770";
          "force directory mode" = "2770";
        };
      };
    };

    # The share account. isSystemUser keeps it out of the login uid range, the
    # locked password and nologin shell keep it from being an identity anywhere
    # but in Samba's own passdb, and it is not in wheel. A leaked SMB password
    # therefore gets the files it already had access to, and stops there.
    users.groups.${group} = { };
    users.users.${user} = {
      isSystemUser = true;
      inherit group;
      description = "Samba share";
      home = cfg.path;
      createHome = false;
      shell = pkgs.shadow; # nologin
      hashedPassword = "!";
    };

    systemd.tmpfiles.settings.samba-share.${cfg.path}.d = {
      inherit user group;
      mode = "2770";
    };

    # Samba keeps its own password database, so the account above needs a Samba
    # password as well as a unix one. Unlike Immich's registration (./immich.nix)
    # this can be re-run: writing a new value into the secret file and switching
    # updates the passdb, rather than only ever creating it.
    systemd.services.samba-account = {
      description = "Samba share account provisioning";
      wantedBy = [ "samba.target" ];
      before = [ "samba-smbd.service" ];
      requiredBy = [ "samba-smbd.service" ];
      after = [
        # smbpasswd maps the Samba account onto a unix uid, so the unix user has
        # to exist first. On the very first boot after enabling this, that is not
        # a given: userborn is what creates it.
        "userborn.service"
        # /var/lib/samba/private is a tmpfiles rule of the upstream module.
        "systemd-tmpfiles-setup.service"
      ];
      path = [
        config.services.samba.package # smbpasswd, pdbedit
        pkgs.coreutils
        pkgs.gnugrep
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;

        # Runs as root: it reads a root-only secret and writes the passdb.
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [
          "/var/lib/samba"
          "/var/cache/samba"
          "/var/lock/samba"
        ];
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        UMask = "0077";
      };
      script = ''
        set -euo pipefail

        if [ ! -r ${lib.escapeShellArg passwordPath} ]; then
          echo "No Samba password at ${passwordPath}." >&2
          echo "Write one out of band, and make it long, random and unique:" >&2
          echo "  install -Dm0400 -o root -g root /dev/stdin ${passwordPath}" >&2
          exit 1
        fi

        password="$(head -n1 ${lib.escapeShellArg passwordPath})"

        # -a adds, plain sets; -s takes the password on stdin, twice, and as root
        # never asks for the old one. Either way the result is the same account
        # holding the password that is in the file right now.
        if pdbedit --list | grep -q "^${user}:"; then
          printf '%s\n%s\n' "$password" "$password" | smbpasswd -s ${user} >/dev/null
        else
          printf '%s\n%s\n' "$password" "$password" | smbpasswd -s -a ${user} >/dev/null
        fi

        smbpasswd -e ${user} >/dev/null
      '';
    };

    # Fail closed: pull in the mount that backs the share, and refuse to start
    # without it. With the drive absent its mount unit fails, and smbd fails with
    # it, rather than exporting an empty mountpoint on the SD card and letting a
    # client fill it. The mount is nofail, so this costs the share, not the boot.
    #
    # A list, because the upstream module already states /var/lib/samba here and
    # systemd's unitOption merges lists by concatenating them.
    systemd.services.samba-smbd.unitConfig.RequiresMountsFor = [ cfg.path ];

    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${cidrCsv} } tcp dport ${toString port} accept
      ip6 saddr { ${ipv6Csv} } tcp dport ${toString port} accept
      tcp dport ${toString port} drop
    '';

    # Resolve ${domain} to this host for every client using the local resolver,
    # so the share is \\${domain}\share on Windows and //${domain}/share on
    # Linux. This is what replaces NetBIOS and WS-Discovery: a name, and no
    # extra listening ports to get it.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
