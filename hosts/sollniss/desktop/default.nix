{ inputs, ... }:
{
  imports = [
    inputs.self.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    nixos.hostname = "nixos";
    profile.graphical.enable = true;
  };
}
