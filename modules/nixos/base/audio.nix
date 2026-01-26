{ config, ... }:
let
  enable = config.prefs.profile.graphical.enable;
in
{
  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = enable;
      alsa.enable = enable;
      alsa.support32Bit = enable;
      pulse.enable = enable;
    };
  };

  security.rtkit.enable = true;
}
