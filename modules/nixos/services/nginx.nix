# Shared front-end for the web services hosted here (SOGo, Immich, ...).
#
# Imported by every module that adds a virtual host, so the hardening and the
# firewall rules below are stated once instead of once per service. Everything
# is keyed off services.nginx.enable, so it disappears with the last service
# that turns nginx on.
{
  config,
  lib,
  ...
}:
let
  port = 80;
  network = config.prefs.network;
  vpn = network.subnets.vpn;

  # Collect CIDRs from all defined subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  cidrCsv = builtins.concatStringsSep ", " subnetCidrs;

  # IPv6 subnets for firewall rules.
  ipv6Allowed = [
    "::1/128"
    "fe80::/10"
  ]
  ++ lib.optional (vpn.cidr6 != null) vpn.cidr6;
  ipv6Csv = builtins.concatStringsSep ", " ipv6Allowed;
in
{
  config = lib.mkIf config.services.nginx.enable {
    services.nginx = {
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
    };

    # Only allow HTTP access from known subnets (LAN + VPN). This host serves
    # plain HTTP, so nothing here may ever be reachable from the internet; the
    # vhosts repeat the same restriction at the nginx level.
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${cidrCsv} } tcp dport ${toString port} accept
      ip6 saddr { ${ipv6Csv} } tcp dport ${toString port} accept
      tcp dport ${toString port} drop
    '';
  };
}
