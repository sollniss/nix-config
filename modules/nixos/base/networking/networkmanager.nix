{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasEntry = network.hosts ? ${hostname};
in
{
  networking.useDHCP = false;
  networking.networkmanager.enable = lib.mkDefault config.prefs.profile.graphical.enable;
  networking.networkmanager.unmanaged = lib.mkIf (hasEntry && config.prefs.nixos.interface != null) [
    "interface-name:${config.prefs.nixos.interface}"
  ];
}
