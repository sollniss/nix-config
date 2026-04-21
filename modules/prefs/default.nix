{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
  network = import ./network.nix;
in
{
  options.prefs = {
    user.name = mkOption {
      type = types.str;
      description = "Primary username for this configuration.";
    };

    nixos.hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary hostname for this configuration.";
    };

    nixos.interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary network interface for this host.";
    };

    profile = {
      graphical.enable = mkEnableOption "Graphical profile capability flag.";
    };

    network = mkOption {
      type = types.attrs;
      default = network;
      readOnly = true;
      description = "Centralized network topology. See prefs/network.nix.";
    };

    hosted = {
      ssh.enable = mkEnableOption "OpenSSH server with restrictive firewall rules.";
      vpn.enable = mkEnableOption "WireGuard VPN server.";
      dns.enable = mkEnableOption "dnscrypt-proxy encrypted DNS resolver.";
      calendar.enable = mkEnableOption "Baikal CalDAV/CardDAV calendar and contacts server.";
    };
  };
}
