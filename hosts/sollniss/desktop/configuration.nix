{
  inputs,
  config,
  pkgs,
  ...
}:
let
  nixosModules = with inputs.self.nixosModules; [
    core
    base

    desktops.cosmic

    programs.protonvpn
  ];
in
{
  imports = nixosModules;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  #boot.kernelPackages = pkgs.linuxPackages_latest; # Can cause nvidia driver build to fail.

  #hardware.keyboard.qmk.enable = true;
  #services.udev.packages = [pkgs.via];

  #environment.systemPackages = with pkgs; [
  #  lutris
  #  gamemode
  #  wineWow64Packages.stable
  #  winetricks
  #  wineWow64Packages.waylandFull
  #];

  users.users.${config.prefs.user.name} = {
    isNormalUser = true;
    description = config.prefs.user.name;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  services.printing.enable = true;

  home-manager.users.${config.prefs.user.name} = {
    imports = [
      ./home.nix
    ];
  };
}
