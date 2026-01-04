{
  inputs,
  vars,
  pkgs,
  ...
}: let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base.shell
    themes.catppuccin

    programs.shelltools
    programs.fish
    programs.helix
  ];
in {
  imports = homeManagerModules;

  programs.home-manager.enable = true;
  home.username = vars.username;
  home.homeDirectory = "/home/${vars.username}";
  home.stateVersion = "25.05";

  programs.bash = {
    enable = true;
  };

  # Extra packages.
  home.packages = with pkgs; [
    # development
    gopls # Go LSP
    gofumpt
    gcc
    delve
    #nil # Nix LSP
    nixd
    alejandra
  ];

  programs.zed-editor = {
    installRemoteServer = true;
  };

  # Extra programs.
  programs.go = {
    enable = true;
    env.GOPATH = "/home/${vars.username}/code/go";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
