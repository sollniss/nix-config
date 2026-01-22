{
  inputs,
  vars,
  pkgs,
  config,
  ...
}: let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base.terminal
    themes.catppuccin

    programs.shelltools
    programs.fish
    programs.helix

    dev.go
    dev.nix
  ];
in {
  imports = homeManagerModules;

  home.stateVersion = "25.05";

  # Extra packages.
  #home.packages = with pkgs; [
  #];

  programs.zed-editor = {
    installRemoteServer = true;
  };

  programs.git = {
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
