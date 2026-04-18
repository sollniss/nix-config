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
  listenAddrs4 = [
    "127.0.0.1"
    self.ip
  ]
  ++ lib.optional config.prefs.hosted.vpn.enable vpn.gateway;

  listenAddrs6 = [
    "::1"
  ]
  ++ lib.optional (config.prefs.hosted.vpn.enable && vpn ? gateway6) vpn.gateway6;

  listenSockets =
    (map (addr: "${addr}:53") listenAddrs4) ++ (map (addr: "[${addr}]:53") listenAddrs6);

  # Derive IPv4 allowed subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  ipv4Allowed = [ "127.0.0.0/8" ] ++ subnetCidrs;

  # Use standard defaults for IPv6.
  ipv6Allowed = [
    "::1/128"
    "fe80::/10"
    "fd00::/8"
  ];

  ipv4Csv = builtins.concatStringsSep ", " ipv4Allowed;
  ipv6Csv = builtins.concatStringsSep ", " ipv6Allowed;
in
{
  config = lib.mkIf config.prefs.hosted.dns.enable {
    services.dnscrypt-proxy = {
      enable = true;

      # Take full control of the configuration, do not merge upstream defaults.
      upstreamDefaults = false;

      settings = {
        listen_addresses = listenSockets;

        # Protocol selection
        dnscrypt_servers = false;
        doh_servers = true;
        odoh_servers = false; # As of Aptil 2026 there exists literally only a single ODoH relay ...
        ipv6_servers = true;
        http3 = true;

        # Server requirements
        require_dnssec = true;
        require_nolog = true;
        require_nofilter = false; # Quad9 servers filter malware by default.

        # Privacy hardening
        tls_disable_session_tickets = true;
        block_unqualified = true;
        block_undelegated = true;
        ignore_system_dns = true;

        # Performance
        max_clients = 250;
        timeout = 5000;
        keepalive = 30;

        # Load balancing: pick from the two fastest servers.
        lb_strategy = "p2";
        lb_estimator = true;

        # Under high load, reduce per-query timeout to fail fast instead of piling up.
        timeout_load_reduction = 0.75;

        # Cache
        cache = true;
        cache_size = 4096;
        cache_min_ttl = 2400;
        cache_max_ttl = 86400;
        cache_neg_min_ttl = 60;
        cache_neg_max_ttl = 600;

        # Bootstrap & startup
        bootstrap_resolvers = [
          "9.9.9.9:53"
          "149.112.112.112:53"
          "[2620:fe::fe]:53"
          "[2620:fe::9]:53"
        ];
        netprobe_timeout = 60;
        netprobe_address = "9.9.9.9:53";

        # Logging
        log_files_max_size = 10;
        log_files_max_age = 7;
        log_files_max_backups = 1;

        # Use Quad9 DoH servers only
        server_names = [
          "doh-ip4-port443-filter-pri"
          "doh-ip4-port443-filter-alt"
          "doh-ip4-port443-filter-alt2"
          "doh-ip6-port443-filter-pri"
          "doh-ip6-port443-filter-alt"
          "doh-ip6-port443-filter-alt2"
        ];
        sources = {
          quad9-resolvers-doh = {
            urls = [
              "https://quad9.net/dnscrypt/quad9-resolvers-doh.md"
              "https://raw.githubusercontent.com/Quad9DNS/dnscrypt-settings/main/dnscrypt/quad9-resolvers-doh.md"
            ];
            cache_file = "/var/cache/dnscrypt-proxy/quad9-resolvers-doh.md";
            minisign_key = "RWTp2E4t64BrL651lEiDLNon+DqzPG4jhZ97pfdNkcq1VDdocLKvl5FW";
          };
        };
      };
    };

    # Wait for time sync before starting so DNSSEC validation
    # does not fail due to an incorrect clock (Pi has no RTC).
    systemd.services.dnscrypt-proxy = {
      after = [ "time-sync.target" ];
      wants = [ "time-sync.target" ];
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
