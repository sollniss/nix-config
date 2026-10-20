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

    # VCS identity from prefs, so hosts don't restate it. jujutsu is enabled by
    # programs/devtools.nix; the settings are inert where it isn't.
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
