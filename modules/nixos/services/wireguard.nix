{
  lib,
  config,
  pkgs,
  ...
}:
let
  port = 443; # Pretend to be QUIC to bypass strict firewalls.
  iface = "wg0";
  keyPath = "/etc/wireguard/private.key";
  network = config.prefs.network;
  vpn = network.subnets.vpn;

  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  hasIPv6 = vpn ? gateway6;

  # Derive WireGuard peers from the VPN subnet.
  vpnPeers = lib.pipe network.hosts [
    builtins.attrValues
    (builtins.filter (h: h.subnet == "vpn"))
    (map (h: {
      PublicKey = h.wgPubKey;
      AllowedIPs = [ "${h.ip}/32" ] ++ lib.optional (h ? ip6) "${h.ip6}/128";
    }))
  ];

  # Inner MTU is 1420 (WireGuard default).
  # MSS must fit both IPv4 (MTU − 40) and IPv6 (MTU − 60) inner packets.
  # Use the smaller value (1360) so a single clamp covers both families.
  mss = 1360;
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

      # Accept Router Advertisements even when IPv6 forwarding is enabled
      # (e.g. by WireGuard's IPMasquerade). Without this, networkd sets
      # accept_ra=1 which the kernel ignores when forwarding is active,
      # causing the host to lose its SLAAC addresses. With this explicit
      # setting, networkd uses accept_ra=2 when it detects forwarding.
      networks."10-${self.subnet}".networkConfig.IPv6AcceptRA = true;

      networks."50-${iface}" = {
        matchConfig.Name = iface;
        address = [
          "${vpn.gateway}/${toString vpn.prefixLength}"
        ]
        ++ lib.optional hasIPv6 "${vpn.gateway6}/${toString vpn.prefixLength6}";
        networkConfig = {
          IPMasquerade = if hasIPv6 then "both" else "ipv4";
        };
        linkConfig.RequiredForOnline = "no";
      };

      wait-online.anyInterface = true;
    };

    boot.kernel.sysctl = {
      # Explicitly enable global IP forwarding. systemd-networkd's IPMasquerade=
      # is supposed to imply this via networkd.conf, but in practice (systemd 256+)
      # it only sets the per-interface sysctl, not the global net.ipv4.ip_forward.
      "net.ipv4.ip_forward" = 1;
      # Prevent conntrack from flaging legitimate packets on long-lived connections
      # as "invalid" and the firewall silently dropping them.
      "net.netfilter.nf_conntrack_tcp_be_liberal" = 1;
    }
    // lib.optionalAttrs hasIPv6 {
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # WireGuard UDP port must be open to all for remote access.
    # Authentication is handled by WireGuard's public-key cryptography.
    networking.firewall.allowedUDPPorts = [ port ];

    # Self-contained nftables table for all WireGuard forwarding rules.
    # This avoids depending on the NixOS firewall's filterForward and
    # extraForwardRules, whose chain structure (conntrack vmap, jump to
    # forward-allow) has side-effects we'd have to work around.
    #
    # The table uses an accept policy and only touches wg0 traffic, so it
    # won't interfere with any other forwarding rules.
    networking.nftables.enable = true;
    networking.nftables.tables.wireguard = {
      family = "inet";
      content = ''
        ${
          # Clamp TCP MSS to fit inside the WireGuard tunnel.
          # Both directions must be clamped: the peer's SYN (iifname)
          # tells the remote server the max segment size to send back, and
          # the remote server's SYN-ACK (oifname) tells the peer the max
          # segment size to send out.
          #
          # Runs at mangle priority (-150), before any filter chain, so it
          # sees every SYN/SYN-ACK regardless of conntrack state.
          #
          # The > condition ensures we only clamp DOWN. Without it, a peer
          # advertising a legitimately lower MSS (e.g. 1220 on a
          # constrained path) would be inflated to ${toString mss}, causing
          # the remote server to send segments too large for the peer.
          #
          # NOTE: rt mtu cannot be used. For iifname it evaluates the
          # outgoing route (end0, MTU 1500), which is too large for the
          # tunnel.
          ""
        }
        chain mss-clamp {
          type filter hook forward priority mangle; policy accept;
          iifname "${iface}" tcp flags syn tcp option maxseg size > ${toString mss} tcp option maxseg size set ${toString mss}
          oifname "${iface}" tcp flags syn tcp option maxseg size > ${toString mss} tcp option maxseg size set ${toString mss}
        }

        ${
          # Forward filtering for peers.
          # Policy is accept so non-wg0 traffic passes through untouched.
          ""
        }
        chain forward {
          type filter hook forward priority filter; policy accept;
          iifname "${iface}" accept
          oifname "${iface}" ct state { established, related } accept
          oifname "${iface}" ct state invalid drop
          oifname "${iface}" drop
        }
      '';
    };
  };
}
