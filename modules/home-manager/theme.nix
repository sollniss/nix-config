{
  pkgs,
  ...
}:
{

  # GTK Setup
  #gtk = {
  #  enable = true;
  #  theme.name = "Breeze-Dark";
  #  #gtk3 = {
  #  #  extraConfig.gtk-application-prefer-dark-theme = true;
  #  #};
  #};

  # GTK
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  # Default fonts.
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.symbols-only
  ];

  fonts.fontconfig.defaultFonts = {
    monospace = [
      "JetBrains Mono"
      "Symbols Nerd Font"
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

  # shell
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  # fcitx5
  i18n.inputMethod.fcitx5 = {
    #addons = with pkgs; [
    #  fcitx5-mellow-themes # this theme causes crashes on plasma wayland
    #];
    settings.addons = {
      classicui.globalSection = {
        # Font = "Noto Sans CJK JP 12";
        # MenuFont = "Noto Serif 12";
        # TrayFont = "Noto Serif 12";
        Theme = "plasma";
        DarkTheme = "plasma";
        UseDarkTheme = true;
      };
    };
  };

  # VSCode
  programs.vscode.profiles.default.userSettings = { 
    "terminal.integrated.gpuAcceleration" = "auto";

    "editor.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
    "editor.fontLigatures" = true;

    "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
    "terminal.integrated.fontLigatures" = true;
  };
}
