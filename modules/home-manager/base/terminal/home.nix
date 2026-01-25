{config, ...}: {
  home = {
    username = config.meta.profile.username;
    homeDirectory = "/home/${config.meta.profile.username}";
  };
}
