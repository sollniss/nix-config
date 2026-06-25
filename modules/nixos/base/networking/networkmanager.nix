{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasEntry = network.hosts ? ${hostname};
in
{
  networking.useDHCP = false;
  networking.networkmanager = {
    enable = lib.mkDefault config.prefs.profile.graphical.enable;

    # Store connection profiles under /var instead of /etc.
    settings.keyfile.path = "/var/lib/NetworkManager/system-connections";

    # When enabled and we have a static IP entry, configure it via a
    # connection profile. This ensures VPN plugins have a base device to anchor to.
    ensureProfiles = lib.mkIf (hasEntry && config.prefs.nixos.interface != null) {
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
  };

  users.users = lib.optionalAttrs config.networking.networkmanager.enable {
    ${config.prefs.user.name}.extraGroups = [ "networkmanager" ];
  };
}
