{
  config,
  pkgs,
  ...
}:
{
  fonts.fontconfig.enable = config.prefs.profile.graphical.enable;

  # Default contains unifont and freefont, remove those.
  # Other fonts are extremely common or contains fallbacks;
  # removing them could cause layout problems.
  # Also add noto-fonts as an alternative to unifont.
  fonts.enableDefaultPackages = false;
  fonts.packages = with pkgs; [
    dejavu_fonts
    gyre-fonts
    liberation_ttf
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];
}
