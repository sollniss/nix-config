{...}: {
  imports = [
    ./configuration.nix
  ];

  meta.profile = {
    username = "sollniss";
    hostname = "nixos-wsl";
    graphical.enable = false;
  };
}
