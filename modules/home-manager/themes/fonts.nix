{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.prefs.profile.graphical.enable {
    home.packages = with pkgs; [
      # Default fonts.
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      jetbrains-mono
      nerd-fonts.symbols-only
    ];

    fonts.fontconfig = {
      enable = true;
      #hinting.enable = true;
      #antialias = true;

      defaultFonts = {
        monospace = [
          "JetBrains Mono"
          "Symbols Nerd Font Mono"
          "Noto Sans CJK JP"
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
          "Symbols Nerd Font"
        ];
      };
    };
  };
}
