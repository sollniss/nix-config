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
      # Long, random, and used nowhere else: Samba stores an unsalted MD4 hash
      # of it, which is password equivalent. Generate it in KeePassXC.
      #   install -Dm0400 -o root -g root /dev/stdin /var/lib/secrets/samba-password
      sambaPassword = "/var/lib/secrets/samba-password";
    };
  };
}
