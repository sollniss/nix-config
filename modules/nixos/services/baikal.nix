{
  config,
  lib,
  ...
}:
let
  port = 80;
  network = config.prefs.network;
  vpn = network.subnets.vpn;
  hostname = config.prefs.nixos.hostname;

  # Collect CIDRs from all defined subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  cidrCsv = builtins.concatStringsSep ", " subnetCidrs;

  # IPv6 subnets for firewall rules.
  ipv6Allowed = [
    "::1/128"
    "fe80::/10"
  ] ++ lib.optional (vpn ? cidr6) vpn.cidr6;
  ipv6Csv = builtins.concatStringsSep ", " ipv6Allowed;
in
{
  config = lib.mkIf config.prefs.hosted.calendar.enable {
    services.baikal = {
      enable = true;
      virtualHost = hostname;
    };

    # Nginx serves Baikal's PHP frontend directly on port 80.
    # No separate reverse-proxy layer is involved; the firewall
    # rules below restrict access instead.
    services.nginx = {
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      virtualHosts.${hostname} = {
        default = true; # Accept requests by IP as well as by hostname.
      };
    };

    # Only allow HTTP access from known subnets (LAN + VPN).
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${cidrCsv} } tcp dport ${toString port} accept
      ip6 saddr { ${ipv6Csv} } tcp dport ${toString port} accept
      tcp dport ${toString port} drop
    '';
  };
}
