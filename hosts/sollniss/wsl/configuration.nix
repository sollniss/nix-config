# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ inputs, config, lib, pkgs, vars, ... }:
let
  nixosModules = with inputs.self.nixosModules; [
    core
    common.shell
  ];
in
{
  #imports = [
  #  #./hardware-configuration.nix
  #] ++ nixosModules;

  imports = nixosModules;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  wsl.enable = true;
  wsl.defaultUser = vars.username;

  programs.git = {
    enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${vars.username}/nix-config"; # Sets NH_OS_FLAKE variable
  };

  home-manager.users.${vars.username} = {
    imports = [
      ./home.nix
      inputs.catppuccin.homeModules.catppuccin
    ];
  };
}
