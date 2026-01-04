{
  pkgs,
  lib,
  config,
  ...
}: {
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
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # dconf
  # Set even if Gnome is not enabled.
  dconf.settings = {
    "org/gnome/desktop/peripherals/mouse" = {
      accel-profile = "flat"; # Disable mouse acceleration
    };
    "org/gnome/desktop/input-sources" = {
      per-window = true;
    };
  };

  fonts.fontconfig = {
    #hinting.enable = true;
    #antialias = true;

    defaultFonts = {
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
  };

  # VSCode
  programs.vscode.profiles.default.userSettings =
    lib.attrsets.optionalAttrs config.programs.vscode.enable
    {
      "editor.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
      "editor.fontLigatures" = true;

      "terminal.integrated.fontFamily" = "'JetBrains Mono', 'Symbols Nerd Font', monospace";
      "terminal.integrated.fontLigatures" = true;
    };
}
