{inputs, ...}: {
  imports = [
    inputs.self.prefs
    ./configuration.nix
  ];

  prefs.profile = {
    username = "sollniss";
    hostname = "nixos";
    graphical.enable = true;
  };
}
