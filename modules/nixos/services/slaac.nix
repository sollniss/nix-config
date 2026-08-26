# A stable LAN ULA for this host, and optionally Router Advertisements for it.
{
  config,
  lib,
  ...
}:
let
  cfg = config.prefs.hosted.slaac;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};
  lan = network.subnets.${self.subnet};
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = self.ip6 != null && lan.cidr6 != null && lan.prefixLength6 != null;
        message = "services.slaac: host ${hostname} needs an ip6 and its subnet a cidr6/prefixLength6 (prefs/network.nix).";
      }
    ];

    systemd.network.networks."10-${self.subnet}" = {
      # Static ULA this host answers DNS on. Merges with the IPv4 address list
      # set in base/networking/static.nix.
      address = [ "${self.ip6}/${toString lan.prefixLength6}" ];

      # Advertise the ULA prefix and this host as an IPv6 resolver.
      networkConfig.IPv6SendRA = lib.mkIf cfg.sendRA true;
      ipv6SendRAConfig = lib.mkIf cfg.sendRA {
        # Not a default router.
        RouterLifetimeSec = 0;
        EmitDNS = true;
        DNS = [ self.ip6 ];
      };
      ipv6Prefixes = lib.mkIf cfg.sendRA [
        {
          Prefix = lan.cidr6;
          OnLink = true;
          AddressAutoconfiguration = true;
        }
      ];
    };
  };
}
