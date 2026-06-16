{
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.prefs.profile.graphical.enable {
    home.pointerCursor = {
      size = 24;
      gtk.enable = true;
      x11.enable = true;
    };
  };
}
