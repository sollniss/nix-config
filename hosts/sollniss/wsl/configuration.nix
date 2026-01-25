# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  inputs,
  vars,
  config,
  ...
}: let
  nixosModules = with inputs.self.nixosModules; [
    core
    wsl
    base.terminal
  ];
in {
  #imports = [
  #  #./hardware-configuration.nix
  #] ++ nixosModules;

  imports = nixosModules;

  programs.git = {
    enable = true;
  };

  #programs.nh = {
  #  enable = true;
  #  clean.enable = true;
  #  clean.extraArgs = "--keep-since 4d --keep 3";
  #  flake = "/home/${config.meta.profile.username}/nix-config"; # Sets NH_OS_FLAKE variable
  #};

  home-manager.users.${config.meta.profile.username} = {
    imports = [
      ./home.nix
    ];
  };
}
