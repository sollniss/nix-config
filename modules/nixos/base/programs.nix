{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  buildsLocally = (network.hosts.${hostname}.builder or null) == null;
in
{
  programs.bash.enable = true;

  # Git and nh are only needed on hosts that build locally.
  # Hosts with a remote builder (e.g. the Pi) are deployed to, not built on.
  programs.git.enable = buildsLocally;

  programs.nh = lib.mkIf buildsLocally {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
    flake = "/home/${config.prefs.user.name}/nix-config";
  };
}
