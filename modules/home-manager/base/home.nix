{ config, ... }:
{
  home = {
    username = config.prefs.user.name;
    homeDirectory = "/home/${config.prefs.user.name}";
  };
}
