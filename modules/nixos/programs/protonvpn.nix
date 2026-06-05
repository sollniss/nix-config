{ pkgs, lib, ... }:
{
  environment.systemPackages = with pkgs; [
    proton-vpn
  ];

  # ProtonVPN's OpenVPN backend requires the NM OpenVPN plugin.
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];

  # Full-tunnel VPN can trip reverse path filtering. Loose mode still
  # provides anti-spoofing protection but allows packets with any valid
  # return route.
  networking.firewall.checkReversePath = "loose";
  boot.kernel.sysctl."net.ipv4.conf.all.rp_filter" = 2;
  boot.kernel.sysctl."net.ipv4.conf.default.rp_filter" = 2;
}
