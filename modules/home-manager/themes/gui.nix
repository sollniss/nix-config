{
  pkgs,
  lib,
  config,
  ...
}:
{

  home.packages = with pkgs; [
    # Default fonts.
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    jetbrains-mono
    nerd-fonts.symbols-only
  ];

  home.pointerCursor = {
    name = "phinger-cursors-dark";
    package = pkgs.phinger-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  programs.gnome-shell = {
    extensions = [
      {
        id = "status-icons@gnome-shell-extensions.gcampax.github.com";
        package = pkgs.gnomeExtensions.status-icons;
      }
      {
        id = "dash-to-panel@jderose9.github.com";
        package = pkgs.gnomeExtensions.dash-to-panel;
      }
      {
        id = "kimpanel@kde.org";
        package = pkgs.gnomeExtensions.kimpanel;
      }
    ];
  };

  # dconf
  # Set even if Gnome is not enabled.
  dconf.settings = {
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
    "org/gnome/desktop/input-sources" = {
      per-window = true;
    };
  }
  # Set only if Gnome is actually enabled for the user.
  // (lib.attrsets.optionalAttrs config.programs.gnome-shell.enable {
    "org/gnome/shell/extensions/dash-to-panel" = {
      panel-sizes = ''{"0":40}'';

      dot-position = "BOTTOM";
      dot-style-focused = "SQUARES";
      dot-style-unfocused = "SQUARES";
      dot-color-dominant = true;

      animate-app-switch = false;
      animate-appicon-hover = false;
      animate-window-launch = false;

      appicon-margin = 0;
      appicon-padding = 8;
      appicon-style = "NORMAL";

      panel-top-bottom-margins = 0;
      panel-top-bottom-padding = 0;
      panel-side-margins = 0;
      status-icon-padding = -1;
      tray-padding = -1;
    };
    "org/gnome/desktop/background" = {
      picture-uri = "${./jakub-rozalski-santa-vs-krampuss.jpg}";
      picture-uri-dark = "${./jakub-rozalski-santa-vs-krampuss.jpg}";
    };
  });

  # TODO: This seems to crash sometimes.
  # https://github.com/NixOS/nixpkgs/issues/359129
  programs.plasma = {
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor = {
        theme = "Bibata-Modern-Ice";
        size = 24;
      };
      iconTheme = "Breeze Dark";
      wallpaper = "${./jakub-rozalski-santa-vs-krampuss.jpg}";
    };
  };

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

  # KeePassXC
  programs.keepassxc.settings.GUI.ApplicationTheme = "dark";

  # VSCode
  programs.vscode.profiles.default.userSettings =
    lib.attrsets.optionalAttrs config.programs.vscode.enable
      {
        "editor.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
        "editor.fontLigatures" = true;

        "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
        "terminal.integrated.fontLigatures" = true;
      };

  # WezTerm
  programs.wezterm.extraConfig = ''
    config.color_scheme = 'Dark+'
  '';
}
