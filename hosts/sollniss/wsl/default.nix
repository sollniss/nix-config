{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.prefs
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    nixos.hostname = "nixos-wsl";
    profile.graphical.enable = false;
  };
}
