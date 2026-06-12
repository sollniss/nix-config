# Shared prefs: the portable options consumed by both NixOS and home-manager.
# default.nix layers the NixOS-only nixos.* options on top of this; home-manager
# imports this file directly so prefs.nixos.* never exists in an HM eval.
{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;

  subnetType = types.submodule {
    options = {
      cidr = mkOption { type = types.str; };
      prefixLength = mkOption { type = types.int; };
      gateway = mkOption { type = types.str; };
      cidr6 = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      prefixLength6 = mkOption {
        type = types.nullOr types.int;
        default = null;
      };
      gateway6 = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  hostType = types.submodule {
    options = {
      ip = mkOption { type = types.str; };
      ip6 = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      subnet = mkOption { type = types.str; };
      dns = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      platform = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      builder = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      signingKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      sshPubKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      wgPubKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  networkType = types.submodule {
    options = {
      subnets = mkOption { type = types.attrsOf subnetType; };
      hosts = mkOption { type = types.attrsOf hostType; };
    };
  };
in
{
  options.prefs = {
    user.name = mkOption {
      type = types.str;
      description = "Primary username for this configuration.";
    };

    user.email = mkOption {
      type = types.str;
      description = "Primary email address for this configuration.";
    };

    profile = {
      graphical.enable = mkEnableOption "Graphical profile capability flag.";
    };

    network = mkOption {
      type = networkType;
      default = import ./network.nix;
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
