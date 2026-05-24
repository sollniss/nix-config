{
  config,
  ...
}:
{
  virtualisation.docker.enable = true;

  users.users.${config.prefs.user.name}.extraGroups = [ "docker" ];
}
