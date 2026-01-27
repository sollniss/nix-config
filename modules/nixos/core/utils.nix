{ config, ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${config.prefs.user.name}/nix-config"; # Sets NH_OS_FLAKE variable
  };
}
