{ inputs, ... }:
{
  imports = [
    inputs.self.prefs
    ./home.nix
  ];

  prefs = {
    user.name = "sollniss";
    profile.graphical.enable = false;
  };
}
