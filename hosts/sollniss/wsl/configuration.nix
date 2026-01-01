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
  wsl = {
    enable = true;
    defaultUser = vars.username;
    startMenuLaunchers = true;
    interop = {
      includePath = false;
      register = true;
    };
  };

  services = {
    xserver.enable = lib.mkForce false;
    openssh.enable = lib.mkForce false;

    # resolv.conf is managed by wsl
    resolved.enable = lib.mkForce false;
  };

  networking = {
    # we don't really need this since windows manages this for us
    firewall.enable = lib.mkForce false;
  };

  # allow opening files and links in Windows from WSL
  environment.variables.BROWSER = lib.mkForce "wsl-open";
  environment.systemPackages = with pkgs; [
    wsl-open
  ];


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
