{
  inputs,
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  nixosModules = with inputs.self.nixosModules; [
    common

    desktops.gnome
  ];
in
{
  imports = [
    ./hardware-configuration.nix
  ]
  ++ nixosModules;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixos"; # Define your hostname.

  #virtualisation.waydroid.enable = true;
  networking.nftables.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    wezterm
  ];

  programs.steam = {
    enable = true;
  };

  home-manager.users.sollniss = import ./home.nix;
}
