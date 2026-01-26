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

    # dconf
    # Set even if Gnome is not enabled.
    #dconf.settings = {
    #  "org/gnome/desktop/peripherals/mouse" = {
    #    accel-profile = "flat"; # Disable mouse acceleration
    #  };
    #  "org/gnome/desktop/input-sources" = {
    #    per-window = true;
    #  };
    #};
  };
}
