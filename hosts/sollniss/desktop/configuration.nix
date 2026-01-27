{
  inputs,
  pkgs,
  config,
  ...
}:
let
  nixosModules = with inputs.self.nixosModules; [
    core
    base

    desktops.cosmic
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

  #hardware.keyboard.qmk.enable = true;
  #services.udev.packages = [pkgs.via];

  users.users.${config.prefs.user.name} = {
    isNormalUser = true;
    description = config.prefs.user.name;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  home-manager.users.${config.prefs.user.name} = {
    imports = [
      ./home.nix
    ];
  };
}
