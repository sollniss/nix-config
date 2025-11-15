{
  pkgs,
  ...
}:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kate
    khelpcenter
    konsole
    krdp
  ];

  #qt = {
  #  enable = true;
  #  platformTheme = "kde"; # this seems to crash plasma wayland
  #};
}