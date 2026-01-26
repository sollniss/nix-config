{ config, ... }:
{
  home = {
    username = config.prefs.profile.username;
    homeDirectory = "/home/${config.prefs.profile.username}";
  };
}
