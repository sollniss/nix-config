{ pkgs, ... }:
{
  # FIXME: Can't get wireguard working.

  #networking.firewall.checkReversePath = "loose";
  #networking.firewall.enable = false;
  #networking.useDHCP = false;
  environment.systemPackages = with pkgs; [
    #wireguard-tools
    #proton-vpn-cli
    protonvpn-gui
  ];

  #services.gnome.gnome-keyring.enable = true;
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
}
