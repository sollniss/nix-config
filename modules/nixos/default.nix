# Leaf modules are paths (the module system deduplicates by path, see
# services/default.nix); nested registries are imported so their entries can be
# addressed as attributes (desktops.cosmic, services.nas, ...).
{
  core = ./core;
  base = ./base;
  desktops = import ./desktops;
  programs = import ./programs;
  services = import ./services;
  wsl = ./wsl.nix;
}
