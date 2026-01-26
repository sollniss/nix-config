{ config, ... }:
{
  networking = {
    hostName = config.prefs.profile.hostname;
  };
}
