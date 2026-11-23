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

    xdg.mimeApps = lib.mkIf config.prefs.profile.graphical.enable {
      enable = true;
      defaultApplications =
        lib.genAttrs [
          "image/png"
          "image/jpeg"
          "image/gif"
          "image/webp"
          "image/bmp"
          "image/tiff"
          "image/avif"
          "image/heic"
          "image/jxl"
        ] (_: "qimgv.desktop")
        // lib.genAttrs [
          "video/mp4"
          "video/x-matroska"
          "video/webm"
          "video/quicktime"
          "video/x-msvideo"
          "video/mpeg"
          "audio/mpeg"
          "audio/flac"
          "audio/ogg"
          "audio/opus"
          "audio/x-wav"
          "audio/mp4"
          "audio/x-m4a"
        ] (_: "vlc.desktop");
    };

    programs = {
      home-manager.enable = true;
      git.enable = true;
      bash.enable = true;
    };

    programs.git.settings.user = lib.mkIf (config.prefs.user.email != null) {
      name = config.prefs.user.name;
      email = config.prefs.user.email;
    };
    programs.jujutsu.settings.user = lib.mkIf (config.prefs.user.email != null) {
      name = config.prefs.user.name;
      email = config.prefs.user.email;
    };
  };
}
