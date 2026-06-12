{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    nixos.hostname = "nixos";
    profile.graphical.enable = true;
  };
}
