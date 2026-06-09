{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager.prefs
    ./home.nix
  ];

  prefs = {
    user.name = "sollniss";
    profile.graphical.enable = false;
  };
}
