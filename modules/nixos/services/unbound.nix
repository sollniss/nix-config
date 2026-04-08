{
  config,
  lib,
  ...
}:
let
  network = config.prefs.network;
  self = network.hosts.${config.prefs.nixos.hostname};
  vpn = network.subnets.vpn;

  # Derive listen addresses: loopback + host LAN IP + VPN gateway (if VPN is hosted).
  listenAddrs = [
    "127.0.0.1"
    self.ip
  ]
  ++ lib.optional config.prefs.hosted.vpn.enable vpn.gateway;

  # Derive IPv4 allowed subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  ipv4Allowed = [ "127.0.0.0/8" ] ++ subnetCidrs;

  # IPv6 subnets are not modeled in network.nix; keep standard defaults.
  ipv6Allowed = [
    "::1/128"
    "fe80::/10"
    "fd00::/8"
  ];

  allSubnets = ipv4Allowed ++ ipv6Allowed;
  ipv4Csv = builtins.concatStringsSep ", " ipv4Allowed;
  ipv6Csv = builtins.concatStringsSep ", " ipv6Allowed;
in
{
  config = lib.mkIf (false && config.prefs.hosted.dns.enable) {
    services.unbound = {
      enable = true;
      settings = {
        server = {
          interface = listenAddrs;

          port = 53;

          access-control = map (s: "${s} allow") allSubnets;

          # Performance (tuned for Raspberry Pi).
          num-threads = 4;
          msg-cache-slabs = 4;
          rrset-cache-slabs = 4;
          infra-cache-slabs = 4;
          key-cache-slabs = 4;
          so-reuseport = true;

          # Cache sizes (tuned for 4GB Pi).
          rrset-cache-size = "256m";
          msg-cache-size = "128m";

          # Prefetch records before they expire.
          prefetch = true;
          prefetch-key = true;

          # Serve stale cache entries while refreshing in the background.
          # This is the key setting that would have prevented the nsncd crash:
          # even if upstream is unreachable, cached answers are still served.
          serve-expired = true;
          serve-expired-ttl = 86400; # Serve stale entries for up to 24h.

          # DNSSEC hardening.
          harden-glue = true;
          harden-dnssec-stripped = true;
          harden-referral-path = true;
          harden-algo-downgrade = true;
          use-caps-for-id = true;
          harden-below-nxdomain = true;

          # Privacy.
          hide-identity = true;
          hide-version = true;
          qname-minimisation = true;
          aggressive-nsec = true;
        };
      };
    };

    # Open DNS port for known subnets only.
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${ipv4Csv} } tcp dport 53 accept
      ip saddr { ${ipv4Csv} } udp dport 53 accept
      ip6 saddr { ${ipv6Csv} } tcp dport 53 accept
      ip6 saddr { ${ipv6Csv} } udp dport 53 accept
      tcp dport 53 drop
      udp dport 53 drop
    '';
  };
}
