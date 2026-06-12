{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    inputs.self.modules.nixos.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    nixos.hostname = "raspberrypi";
    hosted.ssh.enable = true;
    hosted.vpn.enable = true;
    hosted.dns.enable = true;
    hosted.calendar.enable = true;
  };
}
