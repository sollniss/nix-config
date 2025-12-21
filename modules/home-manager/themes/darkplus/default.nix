{
  pkgs,
  ...
}:
{
  # https://github.com/phisch/phinger-cursors
  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
  };

  # fcitx5
  i18n.inputMethod.fcitx5 = {
    settings.addons = {
      classicui.globalSection = {
        Theme = "plasma";
        DarkTheme = "plasma";
        UseDarkTheme = true;
      };
    };
  };

  # WezTerm
  programs.wezterm.extraConfig = ''
    config.color_scheme = "Dark+"
  '';

  # Helix
  programs.helix.settings.theme = "dark_plus";

  # Bat
  programs.bat.config.theme = "Visual Studio Dark+";

  # KeePassXC
  programs.keepassxc.settings.GUI.ApplicationTheme = "dark";
}
