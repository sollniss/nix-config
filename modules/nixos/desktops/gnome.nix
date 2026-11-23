{
  pkgs,
  ...
}:
{
  services.displayManager = {
    gdm.enable = true;
  };
  services.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    #baobab      # disk usage analyzer
    cheese # photo booth
    #eog         # image viewer
    epiphany # web browser
    #gedit       # text editor
    #simple-scan # document scanner
    totem # video player
    yelp # help viewer
    #evince      # document viewer
    #file-roller # archive manager
    geary # email client
    seahorse # password manager

    #gnome-calculator gnome-calendar gnome-characters gnome-clocks gnome-contacts
    #gnome-font-viewer gnome-logs gnome-maps gnome-music gnome-photos gnome-screenshot
    #gnome-system-monitor gnome-weather gnome-disk-utility pkgs.gnome-connections
    gnome-characters
    gnome-contacts
    gnome-music
    gnome-photos
    gnome-weather
    gnome-clocks
  ];
}
