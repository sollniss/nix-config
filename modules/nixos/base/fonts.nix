{ config, ... }:
{
  fonts.fontconfig.enable = config.prefs.profile.graphical.enable;
}
