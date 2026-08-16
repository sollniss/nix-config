{ ... }:
{
  # cosmic-portals.conf is `default=cosmic;gtk;`, and COSMIC's portal does not implement the
  # GNOME namespace, so button-layout falls through to dconf.
  dconf.settings."org/gnome/desktop/wm/preferences".button-layout = "appmenu:minimize,maximize,close";
}
