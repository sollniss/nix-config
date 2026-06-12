{
  inputs,
  pkgs,
  config,
  ...
}:
let
  # Terminal-only config, so no UI stuff needed.
  homeManagerModules = with inputs.self.modules.homeManager; [
    base
    themes
    programs.shelltools
    programs.helix
    programs.fish
    programs.ssh
  ];
in
{
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
      name = config.prefs.user.name;
      email = config.prefs.user.email;
    };
  };
}
