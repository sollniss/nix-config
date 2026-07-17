# IPv6 SLAAC + Router Advertisements for the LAN.
#
#   1. Assigns itself a stable ULA (prefs.network.subnets.lan.cidr6) and answers
#      DNS on it. The ULA never rotates with the ISP prefix, unlike a GUA.
#   2. Sends its own Router Advertisements announcing that ULA prefix on-link
#      (so clients autoconfigure a ULA and can reach this host directly) and
#      itself as an IPv6 resolver via the RDNSS option (RFC 8106). RouterLifetime
#      is 0, so this host is never treated as a default router.
#
# Android honours RDNSS and starts resolving via this host immediately (it
# ignores DHCPv6 entirely). Windows and other DHCPv6 clients take their IPv6 DNS
# from the router's DHCPv6 reply.
#
# IPv6 forwarding and accept_ra=2 (needed so this host keeps its own GUA while
# also sending RAs) are already provided by services.wireguard, which is always
# co-enabled here; this module assumes that and does not redefine them.
{
  config,
  lib,
  ...
}:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};
  lan = network.subnets.${self.subnet};
in
{
  config = lib.mkIf config.prefs.hosted.slaac.enable {
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
      networkConfig.IPv6SendRA = true;
      ipv6SendRAConfig = {
        # Not a default router.
        RouterLifetimeSec = 0;
        EmitDNS = true;
        DNS = [ self.ip6 ];
      };
      ipv6Prefixes = [
        {
          Prefix = lan.cidr6;
          OnLink = true;
          AddressAutoconfiguration = true;
        }
      ];
    };
  };
}
