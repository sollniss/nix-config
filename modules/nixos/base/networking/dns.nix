{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasEntry = network.hosts ? ${hostname} && network.hosts.${hostname}.dns != [ ];

  fallbackDns = [
    # Quad9
    "2620:fe::fe"
    "2620:fe::9"
    "9.9.9.9"
    "149.112.112.112"
  ];

  dnsServers = if hasEntry then network.hosts.${hostname}.dns else fallbackDns;
in
{
  networking = {
    nameservers = dnsServers;
    # Prevent other network managers from overriding the dns settings.
    dhcpcd.extraConfig = "nohook resolv.conf";
    networkmanager.dns = lib.mkIf config.networking.networkmanager.enable "none";

    # networking.nameservers only feeds into resolv.conf via scripted networking if networkd is disabled.
    # networkd only feeds into resolv.conf if resolved is enabled (which we don't have).
    # Hence, we need to manually write the servers if networkd is enabled.
    resolvconf.extraConfig = lib.mkIf config.networking.useNetworkd "name_servers='${lib.concatStringsSep " " dnsServers}'";
  };
  services.resolved.enable = false;
}
