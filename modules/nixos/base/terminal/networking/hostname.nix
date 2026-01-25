{config, ...}: {
  networking = {
    hostName = config.meta.profile.hostname;
  };
}
