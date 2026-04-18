{ config, ... }:
{
  programs.bash = {
    enable = true;
  };

  programs.git = {
    enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = false;
    clean.extraArgs = "--keep-since 70d --keep 50";
    flake = "/home/${config.prefs.user.name}/nix-config"; # Sets NH_OS_FLAKE variable
  };
}
