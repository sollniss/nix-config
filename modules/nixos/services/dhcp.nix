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

    # DHCP requests arrive as broadcast from 0.0.0.0, so allow port 67 by
    # interface rather than source subnet. DNS (:53) is opened by dnscrypt.
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      iifname "${iface}" udp dport 67 accept
    '';
  };
}
