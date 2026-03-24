{ config, ... }:
{
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
    flake = "/home/${config.prefs.user.name}/nix-config"; # Sets NH_OS_FLAKE variable
  };
}
