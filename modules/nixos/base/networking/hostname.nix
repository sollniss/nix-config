{ config, ... }:
{
  networking = {
    hostName = config.prefs.nixos.hostname;
  };
}
