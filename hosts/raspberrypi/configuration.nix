{
  inputs,
  config,
  lib,
  ...
}:
let
  network = config.prefs.network;

  nixosModules = with inputs.self.nixosModules; [
    core
    base
    services.ssh
    services.dnscrypt
    services.wireguard
  ];
in
{
  imports = nixosModules;

  services.ddclient = {
    enable = true;
    protocol = "dyndns2";
    username = "none";
    server = "dynv6.com";
    passwordFile = "/etc/ddclient/password";
    domains = [
      "76bnh564543.dynv6.net"
    ];
    usev4 = "";
    usev6 = "ifv6, ifv6=${config.prefs.nixos.interface}";
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

  # Trust nixos host to build for us.
  nix.settings.trusted-public-keys = [
    network.hosts.nixos.signingKey
  ];

  # Disable sudo, we can only get root by ssh.
  security.sudo.enable = false;
  users.users.root = {
    hashedPassword = "!"; # Lock account.
    openssh.authorizedKeys.keys = [
      network.hosts.nixos.sshPubKey
    ];
  };

  # Also create a user to check logs, etc.
  users.users.${config.prefs.user.name} = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      network.hosts.nixos.sshPubKey
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
