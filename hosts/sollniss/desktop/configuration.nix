{
  inputs,
  vars,
  pkgs,
  ...
}: let
  nixosModules = with inputs.self.nixosModules; [
    core
    common.gui
    common.shell

    desktops.cosmic
  ];
in {
  imports =
    [
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
    bash
  ];

  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = ["networkmanager" "wheel"];
  };

  #home-manager.users.${vars.username} = import ./home.nix;
  home-manager.users.${vars.username} = {
    imports = [
      ./home.nix
      inputs.catppuccin.homeModules.catppuccin
    ];
  };
}
