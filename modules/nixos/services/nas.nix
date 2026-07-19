{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prefs.hosted.nas;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "nas.pi";
  smbPort = 445;
  nfsPort = 2049;

  user = "nas";
  group = "nas";
  passwordPath = config.prefs.secrets.sambaPassword;

  # A fixed user id.
  # 399 is out of reach of both NixOS (400-999)
  # and nixpkgs' static ids.
  id = 399;

  wgIface = "wg0";

  subnets = builtins.attrValues network.subnets;
  cidrs = map (s: s.cidr) subnets;
  cidrs6 = builtins.filter (c: c != null) (map (s: s.cidr6) subnets);

  # Samba allow list.
  hostsAllow = [
    "127.0.0.1"
    "::1"
  ]
  ++ cidrs
  ++ cidrs6;

  # NFS clients, pinned by address.
  nfsClients = lib.pipe network.hosts [
    (lib.filterAttrs (name: h: name != hostname && h.platform != null))
    builtins.attrValues
  ];
  nfsAddrs4 = map (h: h.ip) nfsClients;
  nfsAddrs6 = builtins.filter (a: a != null) (map (h: h.ip6) nfsClients);
  nfsAddrs = nfsAddrs4 ++ nfsAddrs6;

  # The NFS allow list.
  exportOptions = builtins.concatStringsSep "," [
    "rw"
    "sync"
    "no_subtree_check"

    # The NFS equivalent of Samba's `force user`.
    "all_squash"
    "anonuid=${toString id}"
    "anongid=${toString id}"

    # Only a privileged source port may mount.
    "secure"

    # Pin the fs id, so filehandles survive a remount.
    "fsid=1"
  ];
  exports = builtins.concatStringsSep " " (map (a: "${a}(${exportOptions})") nfsAddrs);

in
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf cfg.enable {
    # SMB, for Windows.
    services.samba = {
      enable = true;

      # NetBIOS name service is legacy.
      nmbd.enable = false;
      # Only ever used to join an Active Directory domain.
      winbindd.enable = false;
      # Never let a non-root user publish a share of their own.
      usershares.enable = false;

      # Would open 139/445 tcp and 137/138 udp to everyone.
      # We write the rules ourselves.
      openFirewall = false;

      settings = {
        global = {
          security = "user";
          "server role" = "standalone server";
          workgroup = "WORKGROUP";
          # Default is "Samba %v", which hands out the version to anyone asking.
          "server string" = "";

          # Listen on 445 only, and on nothing but loopback,
          # the LAN and the tunnel.
          # NetBIOS is off, so port 139 never opens.
          "smb ports" = smbPort;
          "disable netbios" = "yes";
          "bind interfaces only" = "yes";
          interfaces = [
            "lo"
            config.prefs.nixos.interface
          ]
          ++ lib.optional config.prefs.hosted.vpn.enable wgIface;
          "hosts allow" = hostsAllow;
          "hosts deny" = "ALL";

          # Force SMB 3.1.1 or newer.
          "server min protocol" = "SMB3_11";
          "client min protocol" = "SMB3_11";

          # The anti-relay and anti-tamper control.
          "server signing" = "required";

          # No session encryption.
          # Pi has no hardware encryption and we trust the LAN anyways.
          "smb encrypt" = "off";

          # No LANMAN, no NTLMv1.
          "ntlm auth" = "ntlmv2-only";

          # Nothing is anonymous, and a bad password is a failure rather than a
          # silent downgrade to a guest session.
          "guest ok" = "no";
          "map to guest" = "never";
          "restrict anonymous" = 2;
          "invalid users" = [ "root" ];

          # Clients may write whatever they like into the share, so give them no
          # way to reach out of it.
          "follow symlinks" = "no";
          "wide links" = "no";

          # No printers.
          "load printers" = "no";
          printing = "bsd";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";

          # Log to the journal rather than to files under /var/log/samba.
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

          # One pool, one owner.
          "force user" = user;
          "force group" = group;
          "create mask" = "0660";
          "force create mode" = "0660";
          "directory mask" = "2770";
          "force directory mode" = "2770";
        };
      };
    };

    # NFS, for Linux.
    services.nfs = {
      server = {
        # No clients pinned means nothing to serve.
        enable = nfsAddrs != [ ];
        exports = ''
          ${cfg.path} ${exports}
        '';
      };

      # NFSv4 only.
      settings.nfsd = {
        vers3 = false;
        vers4 = true;
        "vers4.0" = false;
        "vers4.1" = true;
        "vers4.2" = true;
        udp = false;
        tcp = true;
      };
    };

    # Setup for account, directory, and firewall.

    # isSystemUser keeps the account out of the login uid range, the locked
    # password and nologin shell keep it from being an identity anywhere but in
    # Samba's own passdb, and it is not in wheel.
    users.groups.${group}.gid = id;
    users.users.${user} = {
      isSystemUser = true;
      uid = id;
      inherit group;
      description = "NAS share";
      home = cfg.path;
      createHome = false;
      shell = pkgs.shadow; # nologin
      hashedPassword = "!";
    };

    systemd.tmpfiles.settings.nas-share.${cfg.path}.d = {
      inherit user group;
      mode = "2770";
    };

    # The pool is single-owner: everything ${user}:${group}, directories 2770
    # (setgid + group-writable) and files 0660 — exactly what the Samba share
    # forces on anything written through it, so every group member (Immich for
    # its XMP sidecars, Navidrome) can read and write. Samba enforces that with
    # `force create mode`/`force directory mode`; NFS has no equivalent. Over NFS
    # `all_squash` fixes the owner to ${user}:${group}, but the mode is whatever
    # the client's umask leaves: a folder created over the share lands 2755 —
    # setgid inherited from its parent, but no group write — which locks the
    # group, and so Immich's sidecar writes, out of every new folder. This puts
    # the mode back on a timer, touching only the entries that are actually wrong
    # so it stays cheap even on a large tree.
    #
    # A default POSIX ACL cannot replace this: the NFS client's umask still
    # clamps the mode at creation, so new folders would come out group-unwritable
    # regardless.
    systemd.services.nas-normalize = {
      description = "Normalize ownership and permissions across the NAS pool";
      after = [ "local-fs.target" ];
      unitConfig.RequiresMountsFor = [ cfg.path ];
      path = [
        pkgs.findutils
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";

        # Runs as root: it has to chown and chmod files it does not own, and set
        # the setgid bit on directories whose group it is not a member of. Keep
        # only the four capabilities that needs — chown, chmod-as-non-owner, set
        # the setgid bit (FSETID), and traversal of the group-only pool
        # directories — and drop the rest.
        CapabilityBoundingSet = [
          "CAP_CHOWN"
          "CAP_DAC_READ_SEARCH"
          "CAP_FOWNER"
          "CAP_FSETID"
        ];
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.path ];
        RestrictAddressFamilies = [ "AF_UNIX" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        # RestrictSUIDSGID must stay off (its default): it seccomp-blocks the
        # `chmod 2770` — setgid on a directory — that this service exists to do.
        UMask = "0077";
      };
      script = ''
        set -euo pipefail
        root=${lib.escapeShellArg cfg.path}

        # Skip symlinks throughout: never chmod a link's target, and the share
        # refuses to follow them anyway.
        find "$root" -mindepth 1 ! -type l \( ! -user ${user} -o ! -group ${group} \) \
          -exec chown -h ${user}:${group} {} +
        find "$root" -mindepth 1 -type d ! -perm 2770 -exec chmod 2770 {} +
        find "$root" -mindepth 1 -type f ! -perm 0660 -exec chmod 0660 {} +
      '';
    };

    systemd.timers.nas-normalize = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # Shortly after boot, then every 15 minutes — the same cadence as
        # Immich's library scan, so freshly dropped folders are already correct
        # by the time it imports and lets you edit them. Persistent catches a run
        # missed while the host was off.
        OnBootSec = "2min";
        OnUnitActiveSec = "15min";
        Persistent = true;
      };
    };

    # Samba keeps its own password database, so the account above needs a Samba
    # password as well as a unix one.
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

    # Fail daemons if mount fails.
    systemd.services.samba-smbd.unitConfig.RequiresMountsFor = [ cfg.path ];
    systemd.services.nfs-server.unitConfig.RequiresMountsFor = [ cfg.path ];
    systemd.services.nfs-mountd.unitConfig.RequiresMountsFor = [ cfg.path ];

    # SMB is open to the subnets.
    # NFS is not, so its accept list is the pinned clients, not the subnets.
    prefs.hosted.subnetOnlyPorts.tcp = [ smbPort ];

    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ${lib.optionalString (
        nfsAddrs4 != [ ]
      ) "ip saddr { ${builtins.concatStringsSep ", " nfsAddrs4} } tcp dport ${toString nfsPort} accept"}
      ${lib.optionalString (
        nfsAddrs6 != [ ]
      ) "ip6 saddr { ${builtins.concatStringsSep ", " nfsAddrs6} } tcp dport ${toString nfsPort} accept"}
      tcp dport ${toString nfsPort} drop
    '';

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
