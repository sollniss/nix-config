{
  base = import ./base.nix;
  theme = import ./theme.nix;
  desktops = import ./desktops;
  services = import ./services;
  programs = import ./programs;
}