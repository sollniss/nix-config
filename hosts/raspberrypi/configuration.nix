{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  nixosModules = with inputs.self.modules.nixos; [
    core
    base
    services.ssh
    services.dnscrypt
    services.dhcp
    services.slaac
    services.wireguard
    services.sogo
    services.immich
    services.navidrome
    services.feishin
    services.nas
    services.syncthing
  ];

  sandbox = inputs.self.lib.sandbox;
in
{
  imports = nixosModules;

  system.stateVersion = "25.05";

  environment.etc."machine-id".text = "aebfd9ebc40f42ce9b30b54981e9d88e\n";

  #environment.systemPackages = with pkgs; [
  #  libraspberrypi
  #  raspberrypi-eeprom
  #];

  # Get exactly one global IPv6 address (EUI-64).
  networking.tempAddresses = "disabled";
  systemd.network.networks."10-lan" = {
    networkConfig.IPv6PrivacyExtensions = "no";
    ipv6AcceptRAConfig.DHCPv6Client = "no";
  };

  services.ddclient = {
    enable = true;
    protocol = "dyndns2";
    username = "none";
    server = "dynv6.com";
    passwordFile = config.prefs.secrets.ddclientPassword;
    domains = [
      "c423m89n.76bnh564543.dynv6.net"
    ];
    usev4 = "";
    usev6 = "ifv6, ifv6=${config.prefs.nixos.interface}";

  };
  systemd.services.ddclient = {
    after = [
      "network-online.target"
      # ddclient runs under DynamicUser, so its user is only resolvable via NSS
      # while nsncd is up. Without this, a switch that restarts nsncd can start
      # ddclient in the window where lookups fail.
      "nscd.service"
    ];
    wants = [ "network-online.target" ];
    # Upstream only sets DynamicUser (which already implies a read-only
    # system, no setuid and no new privileges). ddclient talks to the internet
    # and holds the dynv6 secret, so put it in the shared sandbox too, with the
    # network it needs. AF_NETLINK is how `ip` reads the interface's address
    # for usev6.
    #
    # The "!" ExecStartPre steps (upstream's prestart, and the wait below) run
    # as root but stay inside this sandbox: "!" only drops User=, unlike "+".
    # The prestart copies the config into the dynamic user's 0700
    # /run/ddclient, chowns it over and splices the secret in, so the bounding
    # set keeps exactly that, and the syscall filter takes @chown back.
    # ddclient itself runs as the unprivileged dynamic user under
    # NoNewPrivileges, so it can never hold any of these.
    serviceConfig = sandbox // {
      # Wait for a routable ipv6 address.
      ExecStartPre = [
        (lib.concatStringsSep " " [
          "!-${config.systemd.package}/lib/systemd/systemd-networkd-wait-online"
          "--ipv6"
          "--interface=${config.prefs.nixos.interface}:routable"
          "--timeout=60"
        ])
      ];

      CapabilityBoundingSet = [
        "CAP_CHOWN"
        "CAP_DAC_OVERRIDE"
        "CAP_FOWNER"
      ];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_NETLINK"
        "AF_UNIX"
      ];
      SystemCallFilter = sandbox.SystemCallFilter ++ [ "@chown" ];
    };
  };

  # Navidrome and Immich read their libraries out of the NAS share, whose files
  # are owned by the `nas` user and group (files 0660, dirs setgid 2770). Adding
  # both service users to the `nas` group gives them the read access those
  # setgid directories grant the group, and nothing more: neither service ever
  # writes to the share.
  users.users.navidrome.extraGroups = [ "nas" ];
  users.users.immich.extraGroups = [ "nas" ];

  # Daily read-only snapshots of the NAS pool: 14 dailies plus 4 weeklies.
  # A deletion on the share - a client over SMB, Immich emptying its trash -
  # only becomes permanent once the last snapshot holding the file is pruned;
  # until then restoring is a plain cp out of /mnt/pool/snapshots. Snapshots
  # are copy-on-write and the share is append-mostly, so they cost next to
  # nothing. They live on the same disk, though: this protects against
  # deletion, not against the SSD failing.
  #
  # The upstream services.btrbk module insists on sudo or doas (it runs btrbk
  # as its own user and escalates for the btrfs calls), and sudo is disabled
  # on this host on purpose, so this is the same btrbk driven by a plain root
  # oneshot instead.
  systemd.services.btrbk-nas = {
    description = "Snapshot the NAS pool";
    # Without the pool mounted there is nothing to snapshot, so fail fast
    # instead of looking at an empty mountpoint on the SD card.
    unitConfig.RequiresMountsFor = [ "/mnt/pool" ];
    path = [ pkgs.btrfs-progs ];
    serviceConfig = sandbox // {
      Type = "oneshot";

      ExecStartPre = "${pkgs.coreutils}/bin/install -d -m 0700 -o root -g root /mnt/pool/snapshots";

      ExecStart = "${pkgs.btrbk}/bin/btrbk -c ${pkgs.writeText "btrbk-nas.conf" ''
        # Skip the snapshot when nothing changed since the last one.
        snapshot_create onchange
        # Timestamped names so a catch-up run on the same day cannot collide.
        timestamp_format long
        snapshot_preserve_min latest
        snapshot_preserve 14d 4w

        volume /mnt/pool
          snapshot_dir snapshots
          subvolume nas
      ''} run";

      # Snapshotting needs root and CAP_SYS_ADMIN, so the sandbox can only
      # fence in everything else: no network, nothing writable but the pool.
      PrivateNetwork = true;
      ReadWritePaths = [ "/mnt/pool" ];
      IOSchedulingClass = "idle";

      # Of root's capabilities, keep what the btrfs ioctls check (SYS_ADMIN
      # for listing and deleting subvolumes, FOWNER for snapshotting one it
      # does not own), plain root file access, and the chown of the install
      # above. No module loading, ptrace, raw I/O or network admin.
      CapabilityBoundingSet = [
        "CAP_SYS_ADMIN"
        "CAP_FOWNER"
        "CAP_DAC_OVERRIDE"
        "CAP_DAC_READ_SEARCH"
        "CAP_CHOWN"
      ];
      # PrivateDevices stays off: btrfs-progs may look at the block devices.
      # ProtectClock has to follow, as it implies DeviceAllow=char-rtc, and
      # any DeviceAllow turns /dev into an allow-list of just that. The clock
      # is out of reach regardless, with no CAP_SYS_TIME in the bounding set.
      PrivateDevices = false;
      ProtectClock = false;
      # Not the baseline's narrower filter: which calls btrfs-progs makes
      # beyond its ioctls is unconfirmed.
      SystemCallFilter = [ "@system-service" ];
    };
  };
  systemd.timers.btrbk-nas = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      # Take the missed snapshot on the next boot if the pi was off at midnight.
      Persistent = true;
    };
  };

  # We run our own DNS with dnscrypt-proxy.
  services.resolved.enable = lib.mkForce false;

  # Use NTP server IPs directly to break the chicken-and-egg problem:
  # Pi has no hardware clock → boots with wrong time → DNSSEC fails →
  # DNS is broken → NTP can't resolve time servers → stuck.
  networking.timeServers = [
    "162.159.200.1" # time.cloudflare.com
    "162.159.200.123" # time.cloudflare.com
  ];

  # Disable sudo, we can only get root by ssh.
  security.sudo.enable = false;
  users.users.root = {
    hashedPassword = "!"; # Lock account.
    openssh.authorizedKeys.keys = [
      config.prefs.network.hosts.nixos.userPubKey
    ];
  };

  # Minimize SD card writes by keeping logs in memory only.
  services.journald.settings.Journal = {
    Storage = "volatile";
    RuntimeMaxUse = "32M";
  };

  boot.kernel.sysctl = {
    # Suppress all but error-level kernel messages from being logged.
    "kernel.printk" = "3 3 3 3";

    # Yama: only CAP_SYS_PTRACE (root over ssh) may ptrace another process or
    # read its memory. A compromised service account can no longer attach to
    # its own sibling processes, say to lift the Immich API key out of a
    # running curl. There are no interactive users here to debug their own.
    "kernel.yama.ptrace_scope" = 2;

    # io_uring has been a steady source of kernel privilege escalations, and
    # nothing here uses it: Postgres defaults to io_method=worker, libuv's
    # io_uring path is off by default, Samba has no vfs_io_uring configured.
    # Callers get EPERM and fall back to plain syscalls.
    "kernel.io_uring_disabled" = 2;
  };

  # No kexec, no hibernation: the running kernel can only change through a
  # reboot (deploys only add a boot entry). A remote reinstall that kexecs into
  # an installer (nixos-anywhere) needs this off and a reboot first.
  security.protectKernelImage = true;

  # Only root may talk to the nix daemon. Deploys come in as root, and none of
  # the service accounts (immich, nas, sogo, ...) has any business building.
  nix.settings.allowed-users = [ "root" ];
}
