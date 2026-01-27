{ inputs, ... }:
{
  imports = [
    inputs.self.prefs
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    nixos.hostname = "nixos-wsl";
    profile.graphical.enable = false;
  };
}
