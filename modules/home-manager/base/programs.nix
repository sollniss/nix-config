{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = {
    home = lib.mkIf config.prefs.profile.graphical.enable {
      packages = with pkgs; [
        vlc
        signal-desktop
        #anki
      ];

      sessionVariables.ANKI_WAYLAND = "1";
    };

    programs = {
      home-manager.enable = true;
      git.enable = true;
      bash.enable = true;
    };
  };
}
