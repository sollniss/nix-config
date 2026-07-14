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
    services.wireguard
    services.sogo
    services.immich
    services.samba
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
