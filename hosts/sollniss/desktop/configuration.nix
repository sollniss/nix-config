{
  inputs,
  pkgs,
  config,
  ...
}: let
  nixosModules = with inputs.self.nixosModules; [
    core
    base.terminal
    base.gui

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

  #hardware.keyboard.qmk.enable = true;
  #services.udev.packages = [pkgs.via];

  users.users.${config.meta.profile.username} = {
    isNormalUser = true;
    description = config.meta.profile.username;
    extraGroups = ["networkmanager" "wheel"];
  };

  #home-manager.users.${config.meta.profile.username} = import ./home.nix;
  home-manager.users.${config.meta.profile.username} = {
    imports = [
      ./home.nix
    ];
  };
}
