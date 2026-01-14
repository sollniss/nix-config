{
  inputs,
  vars,
  pkgs,
  config,
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
    nameservers = [
      # Quad9
      "2620:fe::fe"
      "2620:fe::9"
      "9.9.9.9"
      "149.112.112.112"

      # Cloudflare
      #"2606:4700:4700::1111"
      #"2606:4700:4700::1001"
      #"1.1.1.1"
      #"1.0.0.1"
    ];
    networkmanager = {
      # Either of these two should be enough to force the nameservers.
      # Set both just to be extra sure.
      dns = "none";
      insertNameservers = config.networking.nameservers;
    };
    # nftables.enable = true; # required only for waydroid
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    bash

    #qmk
    #via
  ];

  #hardware.keyboard.qmk.enable = true;
  #services.udev.packages = [pkgs.via];

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
