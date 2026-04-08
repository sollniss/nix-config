{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasEntry = network.hosts ? ${hostname};
in
{
  config = lib.mkIf hasEntry (
    let
      self = network.hosts.${hostname};
      subnet = network.subnets.${self.subnet};
    in
    {
      networking.dhcpcd.enable = false; # Enabled by default.
      networking.useNetworkd = true;
      systemd.network.networks."10-${self.subnet}" = {
        matchConfig.Name = config.prefs.nixos.interface;
        address = [
          "${self.ip}/${toString subnet.prefixLength}"
        ];
        routes = [
          { Gateway = subnet.gateway; }
        ];
        linkConfig.RequiredForOnline = "routable";
      };
    }
  );
}
