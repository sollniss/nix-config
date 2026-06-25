{ config, lib, ... }:
let
  hasUser = config.prefs.user.name != null;
  hasUserPassword = config.prefs.secrets ? userPassword;
in
{
  users.mutableUsers = false;
  services.userborn.enable = true;

  users.users = lib.mkMerge [
    (lib.optionalAttrs hasUser {
      ${config.prefs.user.name} = {
        isNormalUser = true;
        description = config.prefs.user.name;
        hashedPasswordFile = lib.mkIf hasUserPassword config.prefs.secrets.userPassword;
        extraGroups = [ "wheel" ];
      };
    })

    # Root shares the primary user's password where one is configured.
    { root.hashedPasswordFile = lib.mkIf hasUserPassword config.prefs.secrets.userPassword; }
  ];
}
