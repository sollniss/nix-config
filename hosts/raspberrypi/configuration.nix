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
    services.ssh-failsafe # TRIAL until ~2026-08: see the module header.
    services.dnscrypt
    services.dhcp
    services.slaac
    services.wireguard
    services.sogo
    services.immich
    services.navidrome
    services.feishin
    services.nas
  ];
in
{
  imports = nixosModules;

  system.stateVersion = "25.05";

  environment.etc."machine-id".text = "aebfd9ebc40f42ce9b30b54981e9d88e\n";

  #environment.systemPackages = with pkgs; [
  #  libraspberrypi
  #  raspberrypi-eeprom
  #];

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
    # Wait for a routable ipv6 address.
    serviceConfig.ExecStartPre = [
      (lib.concatStringsSep " " [
        "!-${config.systemd.package}/lib/systemd/systemd-networkd-wait-online"
        "--ipv6"
        "--interface=${config.prefs.nixos.interface}:routable"
        "--timeout=60"
      ])
    ];
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
    serviceConfig = {
      Type = "oneshot";
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
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/mnt/pool" ];
      IOSchedulingClass = "idle";
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

  # btrbk refuses to run if the snapshot directory is missing, and never
  # creates it itself.
  systemd.tmpfiles.settings.btrbk."/mnt/pool/snapshots".d = {
    user = "root";
    group = "root";
    mode = "0700";
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
  services.journald.storage = "volatile";
  services.journald.extraConfig = ''
    RuntimeMaxUse=32M
  '';

  # Suppress all but error-level kernel messages from being logged.
  boot.kernel.sysctl."kernel.printk" = "3 3 3 3";
}
