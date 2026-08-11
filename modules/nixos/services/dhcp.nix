{
  config,
  lib,
  ...
}:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};
  iface = config.prefs.nixos.interface;
  lan = network.subnets.${self.subnet};
in
{
  config = lib.mkIf config.prefs.hosted.dhcp.enable {
    systemd.network.networks."10-${self.subnet}" = {
      networkConfig.DHCPServer = true;
      dhcpServerConfig = {
        # Dynamic pool .150–.249.
        PoolOffset = 150;
        PoolSize = 100;
        DefaultLeaseTimeSec = 86400; # 24h
        MaxLeaseTimeSec = 86400;
        # Advertise the real router as the gateway, not this host.
        EmitRouter = true;
        Router = lan.gateway;
        # Resolve via this host.
        EmitDNS = true;
        DNS = [ self.ip ];
      };
    };

    # A client with no lease yet broadcasts from 0.0.0.0, which no source
    # allowlist can match, so this port cannot go through
    # prefs.hosted.subnetOnlyPorts like the others.
    #
    # DNS (:53) is opened by dnscrypt.
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      iifname "${iface}" ip saddr 0.0.0.0 ip daddr 255.255.255.255 udp dport 67 accept
      iifname "${iface}" ip saddr ${lan.cidr} udp dport 67 accept
      udp dport 67 drop
    '';
  };
}
