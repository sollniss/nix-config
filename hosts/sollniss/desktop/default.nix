{...}: {
  imports = [
    ./configuration.nix
  ];

  meta.profile = {
    username = "sollniss";
    hostname = "nixos";
    graphical.enable = true;
  };
}
