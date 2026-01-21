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
  ];
in {
  imports = homeManagerModules;

  home.stateVersion = "25.05";

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
    env = {
      GOPATH = "${config.home.homeDirectory}/go";
      GOBIN = "${config.home.homeDirectory}/go/bin";
    };
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
