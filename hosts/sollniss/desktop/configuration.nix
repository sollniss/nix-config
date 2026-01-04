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

  networking = {
    hostName = "nixos";
    nameservers = [ "2620:fe::fe" "9.9.9.9" ]; # Quad9 IPv6 and IPv4
    networkmanager = {
      # Either of these two should be enough to force the nameservers.
      # Set both just to be extra sure.
      dns = "none";
      insertNameservers = [ "2620:fe::fe" "9.9.9.9" ];
    };
    # nftables.enable = true; # required only for waydroid
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bash
  ];

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/${vars.username}/nix-config"; # Sets NH_OS_FLAKE variable
  };

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
