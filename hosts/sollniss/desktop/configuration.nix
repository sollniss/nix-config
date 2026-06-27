{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  nixosModules = with inputs.self.modules.nixos; [
    core
    base

    desktops.cosmic

    services.docker

    programs.protonvpn
  ];
in
{
  imports = nixosModules;

  system.stateVersion = "25.05";

  environment.etc."machine-id".text = "221dd93f87d143cdba4f1690f6d4a1f6\n";

  nixpkgs.overlays = [
    (_: prev: {
      openldap = prev.openldap.overrideAttrs (_: {
        # Work around nixpkgs#513245: the failing tests are on i686 only.
        doCheck = !prev.stdenv.hostPlatform.isi686;
      });
    })
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest; # Can cause nvidia driver build to fail.

  #hardware.keyboard.qmk.enable = true;
  #services.udev.packages = [pkgs.via];

  environment.systemPackages = with pkgs; [
    lutris
    gamemode
    wineWow64Packages.stable
    winetricks
    wineWow64Packages.waylandFull
  ];

  services.gnome.gnome-keyring.enable = lib.mkForce false;

  services.printing.enable = true;

  home-manager.users.${config.prefs.user.name} = {
    imports = [
      ./home.nix
    ];
  };
}
