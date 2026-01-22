{
  inputs,
  vars,
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

  users.users.${vars.username} = {
    isNormalUser = true;
    description = vars.username;
    extraGroups = ["networkmanager" "wheel"];
  };

  #home-manager.users.${vars.username} = import ./home.nix;
  home-manager.users.${vars.username} = {
    imports = [
      ./home.nix
    ];
  };
}
