{
  lib,
  pkgs,
  ...
}:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Disable Gnome keyring to be able to use KeePassXC.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  #environment.sessionVariables.QT_QPA_PLATFORMTHEME = "gnome";

  #qt = {
  #  enable = true;
  #  platformTheme = "gnome";
  #  style = {
  #    name = "adwaita-dark";
  #    package = pkgs.adwaita-qt;
  #  };
  #};
}