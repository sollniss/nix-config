{ inputs, config, ... }:
let
  homeManagerModules = with inputs.self.modules.homeManager; [
    base
    theme

    programs.shelltools
    programs.fish
    programs.helix

    programs.devtools
    dev.go
    dev.nix
  ];
in
{
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
      name = config.prefs.user.name;
      email = config.prefs.user.email;
    };
  };
}
