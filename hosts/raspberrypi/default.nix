{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    inputs.self.modules.nixos.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    nixos.hostname = "raspberrypi";

    hosted = {
      ssh.enable = true;
      vpn.enable = true;
      dns.enable = true;
      dhcp.enable = true;
      calendar.enable = true;
      photos.enable = true;
      nas = {
        enable = true;
        path = "/srv/nas";
      };
    };

    secrets = {
      wireguardPrivateKey = "/var/lib/secrets/wireguard-private-key";
      ddclientPassword = "/var/lib/secrets/ddclient-password";
      # install -Dm0400 -o root -g root /dev/stdin /var/lib/secrets/samba-password
      sambaPassword = "/var/lib/secrets/samba-password";
    };
  };
}
