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
        # Accept Router Advertisements even when IPv6 forwarding is enabled
        # (e.g. by WireGuard's IPMasquerade). Without this, networkd sets
        # accept_ra=1 which the kernel ignores when forwarding is active,
        # causing the host to lose its SLAAC addresses. With this explicit
        # setting, networkd uses accept_ra=2 when it detects forwarding.
        networkConfig.IPv6AcceptRA = true;
        linkConfig.RequiredForOnline = "routable";
      };
    }
  );
}
