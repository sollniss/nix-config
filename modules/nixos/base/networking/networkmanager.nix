{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasEntry = network.hosts ? ${hostname};
in
{
  networking.useDHCP = false;
  networking.networkmanager.enable = lib.mkDefault config.prefs.profile.graphical.enable;

  # When NM is enabled and we have a static IP entry, configure it via an NM
  # connection profile. This ensures VPN plugins have a base device to anchor to.
  networking.networkmanager.ensureProfiles =
    lib.mkIf
      (hasEntry && config.prefs.nixos.interface != null && config.networking.networkmanager.enable)
      {
        profiles.static-lan =
          let
            self = network.hosts.${hostname};
            subnet = network.subnets.${self.subnet};
          in
          {
            connection = {
              id = "static-lan";
              type = "ethernet";
              interface-name = config.prefs.nixos.interface;
              autoconnect = "true";
            };
            ipv4 = {
              method = "manual";
              addresses = "${self.ip}/${toString subnet.prefixLength}";
              gateway = subnet.gateway;
            };
            ipv6 = {
              method = "auto";
              addr-gen-mode = "default";
            };
          };
      };
}
