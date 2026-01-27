{ inputs, ... }:
{
  imports = [
    inputs.self.prefs
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    nixos.hostname = "nixos";
    profile.graphical.enable = true;
  };
}
