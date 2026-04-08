{
  lib,
  config,
  pkgs,
  ...
}:
let
  port = 51947;
  iface = "wg0";
  keyPath = "/etc/wireguard/private.key";
  network = config.prefs.network;
  vpn = network.subnets.vpn;

  # Derive WireGuard peers the VPN subnet.
  vpnPeers = lib.pipe network.hosts [
    builtins.attrValues
    (builtins.filter (h: h.subnet == "vpn"))
    (map (h: {
      PublicKey = h.wgPubKey;
      AllowedIPs = [ "${h.ip}/32" ];
    }))
  ];
in
{
  config = lib.mkIf config.prefs.hosted.vpn.enable {
    # Ensure WireGuard private key exists before networkd starts.
    # The key must be readable by the systemd-network user.
    systemd.services.wireguard-key-generate = {
      description = "Generate WireGuard private key if missing";
      wantedBy = [ "systemd-networkd.service" ];
      before = [ "systemd-networkd.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.wireguard-tools ];
      script = ''
        if [ ! -f "${keyPath}" ]; then
          mkdir -p "$(dirname "${keyPath}")"
          wg genkey > "${keyPath}"
          echo "Generated new WireGuard private key at ${keyPath}"
        fi
        chown systemd-network:systemd-network "${keyPath}"
        chmod 640 "${keyPath}"
      '';
    };

    systemd.network = {
      netdevs."50-${iface}" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = iface;
        };
        wireguardConfig = {
          ListenPort = port;
          PrivateKeyFile = keyPath;
        };
        wireguardPeers = vpnPeers;
      };

      networks."50-${iface}" = {
        matchConfig.Name = iface;
        address = [ "${vpn.gateway}/${toString vpn.prefixLength}" ];
        networkConfig = {
          IPMasquerade = "ipv4";
        };
        linkConfig.RequiredForOnline = "no";
      };

      wait-online.anyInterface = true;
    };

    # WireGuard UDP port must be open to all for remote access.
    # Authentication is handled by WireGuard's public-key cryptography.
    networking.firewall.allowedUDPPorts = [ port ];

    # Allow forwarded traffic from WireGuard clients.
    # Clamp TCP MSS to path MTU to avoid PMTU/fragmentation issues,
    # especially for mobile networks.
    networking.firewall.extraForwardRules = ''
      iifname "${iface}" tcp flags syn tcp option maxseg size set rt mtu

      iifname "${iface}" accept
      oifname "${iface}" ct state { established, related } accept
    '';
  };
}
