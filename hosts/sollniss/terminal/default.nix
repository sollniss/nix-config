{...}: {
  imports = [
    ./home.nix
  ];

  prefs.profile = {
    username = "sollniss";
    # Home Manager "terminal" config is not a NixOS system, so hostname is not relevant here.
    # We still provide a stable value to satisfy the option type.
    hostname = "terminal";
    graphical.enable = false;
  };
}
