# Centralized network topology
#
# All host IPs, interfaces, gateways, and nameservers in one place.
# Hosts reference this file instead of hardcoding network values.
{
  # Subnets
  subnets = {
    lan = {
      cidr = "192.168.1.0/24";
      prefixLength = 24;
      gateway = "192.168.1.1";
      # Self-assigned ULA (RFC 4193), independent of the ISP's rotating
      # delegation. Announced on-link by the pi's Router Advertisements
      # (services.slaac) so IPv6 clients have a stable address to reach the
      # pi's resolver at. The ISP GUA prefix stays owned by the real router.
      cidr6 = "fdca:6321:8b7e::/64";
      prefixLength6 = 64;
    };
    vpn = {
      cidr = "10.100.0.0/24";
      prefixLength = 24;
      gateway = "10.100.0.1";
      cidr6 = "fd10:100::/64";
      prefixLength6 = 64;
      gateway6 = "fd10:100::1";
    };
  };

  # Managed hosts
  hosts = {
    nixos = {
      ip = "192.168.1.100";
      subnet = "lan";
      dns = [ "192.168.1.101" ];
      # Trust paths signed by the desktop's signing key for remote deployments.
      # sudo nix-store --generate-binary-cache-key nixos-desktop /etc/nix/signing-key.private /etc/nix/signing-key.public
      signingKey = "nixos-desktop:Zc1ZNwDzEr/fBkktS9yrdDCDavc/koH16xOawRnAEMo=";
      userPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/3EVlnhOuYLxus+1lG83Vto2kv7nAt/XbnYoXtldNd";
      # syncthing device-id --home ~/.local/state/syncthing
      syncthingId = "VJ6CEOF-OEWHVQD-Z4BBDHT-FRJLUJ5-E6BBQA2-DVERJR3-5C3R44E-7JLYWAF";
      platform = "x86_64-linux";
    };
    raspberrypi = {
      ip = "192.168.1.101";
      # Static LAN ULA. The address the pi answers DNS on over IPv6, and the
      # one the router advertises to clients as their IPv6 resolver. Stable
      # across ISP prefix rotations, which a GUA is not - hence a ULA.
      #
      # The router has to advertise it; the pi cannot reach every client by
      # itself. RA RDNSS from the pi (services.slaac sendRA) only reaches
      # clients that honour RDNSS, never DHCPv6-only ones. OpenWrt's odhcpd
      # covers both from a single `list dns` entry, so sendRA is off there.
      #
      # Needs the router's ula_prefix to match subnets.lan.cidr6, so this
      # address sits inside the prefix it advertises on-link.
      ip6 = "fdca:6321:8b7e::101";
      subnet = "lan";
      dns = [
        "127.0.0.1"
        "::1"
      ];
      platform = "aarch64-linux";
      builder = "nixos";
      # cat /var/lib/ssh/ssh_host_ed25519_key.pub
      hostPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5cYk2HDFfgR2OEURV/0YVBptASpddYrD2ciybCLh1R";
      # syncthing device-id --home /var/lib/syncthing/.config/syncthing
      syncthingId = "TL7KH2Z-L5JIM6M-TXIXAU2-L32QKUG-CSL5HBT-VRDJITJ-OHSWJAV-AV6GBAN";
    };
    phone-d = {
      ip = "10.100.0.2";
      ip6 = "fd10:100::2";
      subnet = "vpn";
      wgPubKey = "dVxRwJMIRkR5UmHnGT4V7rpEst2MfqJQ+qrY7LyNA1U=";
      syncthingId = "WMPYVNZ-MMUZJ2Y-NZ7MT2A-ERJIHMU-3OO3TCM-WJPZYVO-PT2BGED-5WMIRQZ";
    };
    phone-m = {
      ip = "10.100.0.3";
      ip6 = "fd10:100::3";
      subnet = "vpn";
      wgPubKey = "rjtoRyh52G6smFCSWr7U6IdJEUuvEXtBdDFsgxwNnCU=";
    };
  };
}
