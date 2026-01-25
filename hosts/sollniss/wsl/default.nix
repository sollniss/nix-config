{...}: {
  imports = [
    ./configuration.nix
  ];

  prefs.profile = {
    username = "sollniss";
    hostname = "nixos-wsl";
    graphical.enable = false;
  };
}
