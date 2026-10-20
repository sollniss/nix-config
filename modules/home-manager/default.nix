# Leaf modules are paths, nested registries are imported; see
# modules/nixos/default.nix.
{
  base = ./base;
  theme = ./theme;
  desktops = import ./desktops;
  services = import ./services;
  programs = import ./programs;
  dev = import ./dev;
}
