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

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.desktopManager.plasma6.enable = true;

  virtualisation.waydroid.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #  wget
    wezterm
  ];

  home-manager.users.sollniss = import ./home.nix;
}
