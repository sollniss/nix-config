{ inputs, ... }:
{
  imports = [
    inputs.self.modules.homeManager.prefs
    ./home.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    profile.graphical.enable = false;
  };
}
