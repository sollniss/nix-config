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

  home.packages = with pkgs; [
    # Default fonts.
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.symbols-only

    # Gnome extensions
    pkgs.gnome-shell-extensions
    gnomeExtensions.dash-to-panel
    gnomeExtensions.kimpanel
  ];

  # Gnome
  dconf.settings = {
    "org/gnome/shell" = {
      enabled-extensions = [
        "status-icons@gnome-shell-extensions.gcampax.github.com"
        "dash-to-panel@jderose9.github.com"
        "kimpanel@kde.org"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "thunderbird.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "firefox.desktop"
        "org.wezfurlong.wezterm.desktop"
        "code.desktop"
      ];
    };
    "org/gnome/shell/extensions/dash-to-panel" = {
      dot-position = " BOTTOM";
      dot-style-focused = "SQUARES";
      dot-style-unfocused = "SQUARES";
      dot-color-dominant = true;

      animate-app-switch = false;
      animate-appicon-hover = false;
      animate-window-launch = false;

      appicon-margin = 0;
      appicon-padding = 4;
      appicon-style = "NORMAL";

      panel-top-bottom-margins = 0;
      panel-top-bottom-padding = 0;
      panel-side-margins = 0;
      status-icon-padding = -1;
      tray-padding = -1;
    };
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      clock-format = "24h";
      clock-show-weekday = true;
      enable-animations = false;
      text-scaling-factor = 1;
      enable-hot-corners = false;
    };
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat"; # Disable mouse acceleration
    };
  };

  #programs.plasma = {
  #  enable = true;
  #  workspace = {
  #    lookAndFeel = "org.kde.breezedark.desktop";
  #    cursor = {
  #      theme = "Bibata-Modern-Ice";
  #      size = 24;
  #    };
  #    iconTheme = "Breeze Dark";
  #    wallpaper = "${./wallpaper.jpg}";
  #  };
  #};

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
