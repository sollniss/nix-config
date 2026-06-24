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
      calendar.enable = true;
    };

    secrets = {
      wireguardPrivateKey = "/var/lib/secrets/wireguard-private-key";
      ddclientPassword = "/var/lib/secrets/ddclient-password";
    };
  };
}
