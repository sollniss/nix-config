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
        vlc # audio, video
        qimgv # images
        signal-desktop
      ];
    };

    programs = {
      home-manager.enable = true;
      git.enable = true;
      bash.enable = true;
    };
  };
}
