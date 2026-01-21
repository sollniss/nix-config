{pkgs, ...}: {
  home.packages = with pkgs; [
    vlc
    signal-desktop
    #anki
  ];

  home.sessionVariables.ANKI_WAYLAND = "1";
}
