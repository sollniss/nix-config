{
  pkgs,
  ...
}:
{
  # Make GNOME dark.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Default fonts.
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    jetbrains-mono
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrainsMono"
    ];

    sansSerif = [
      "Noto Sans"
      "Noto Sans CJK JP"
    ];

    serif = [
      "Noto Serif"
      "Noto Serif CJK JP"
    ];

    emoji = [
      "Noto Color Emoji"
    ];
  };

  i18n.inputMethod.fcitx5 = {
    addons = with pkgs; [
      fcitx5-mellow-themes
    ];
    settings.addons = {
      classicui.globalSection = {
        # Font = "Noto Sans CJK JP 12";
        # MenuFont = "Noto Serif 12";
        # TrayFont = "Noto Serif 12";
        Theme = "Mellow Graphite dark";
        DarkTheme = "Mellow Graphite dark";
        UseDarkTheme = true;
      };
    };
  };

  # VSCode styling.
  programs.vscode.profiles.default.userSettings = {
    "editor.fontFamily" = "'JetBrains Mono', monospace";
    "editor.fontLigatures" = true;
  };
}
