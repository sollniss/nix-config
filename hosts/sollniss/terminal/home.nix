{
  inputs,
  pkgs,
  ...
}: let
  # Terminal-only config, so no UI stuff needed.
  homeManagerModules = with inputs.self.homeManagerModules; [
    base.terminal
    themes.catppuccin
    programs.shelltools
    programs.helix
    programs.fish
  ];
in {
  imports = homeManagerModules;

  home.stateVersion = "25.05";

  # Extra packages.
  home.packages = with pkgs; [
    # development
    #gopls # Go LSP
    #nil # Nix LSP
    nixd
  ];

  # Extra programs.
  programs.go = {
    enable = true;
    env.GOPATH = "code/go";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
