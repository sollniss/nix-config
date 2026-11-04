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
    services.firewall

    programs.protonvpn
  ];
in
{
  imports = nixosModules;

  system.stateVersion = "25.05";

  environment.etc."machine-id".text = "221dd93f87d143cdba4f1690f6d4a1f6\n";

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

  # Syncthing
  # 22000 for the sync protocol (TCP) and QUIC (UDP)
  # 21027 for local discovery
  prefs.hosted.subnetOnlyPorts = {
    tcp = [ 22000 ];
    udp = [
      22000
      21027
    ];
  };

  # NAS share on the pi, over NFSv4.
  users.groups.nas.gid = 399;
  users.users.${config.prefs.user.name}.extraGroups = [ "nas" ];

  fileSystems."/mnt/nas" = {
    device = "${config.prefs.network.hosts.raspberrypi.ip}:/srv/nas";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "x-systemd.automount" # mount on first access, not at boot
      "noauto" # so a missing pi never holds up boot
      "_netdev" # it is a network filesystem
    ];
  };

  home-manager.users.${config.prefs.user.name} = {
    imports = [
      ./home.nix
    ];
  };
}
