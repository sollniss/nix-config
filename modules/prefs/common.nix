# Shared prefs: the portable options consumed by both NixOS and home-manager.
# default.nix layers the NixOS-only nixos.* and hosted.* options on top of this;
# home-manager imports this file directly so neither exists in an HM eval.
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
      userPubKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      hostPubKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      wgPubKey = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      syncthingId = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
    };
  };

  syncFolderType = types.submodule {
    options = {
      id = mkOption { type = types.str; };
      hosts = mkOption { type = types.listOf types.str; };
      untrusted = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Subset of hosts that participate without ever seeing the contents:
          they store and forward only ciphertext.
        '';
      };
      receiveOnly = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Subset of hosts holding a backup replica: they receive changes but
          never propagate local ones back.
        '';
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
      type = types.nullOr types.str;
      default = null;
      description = "Primary username, or null on hosts without an interactive user.";
    };

    user.email = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary email address, or null on hosts without an interactive user.";
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

    sync = mkOption {
      type = types.submodule {
        options = {
          folders = mkOption { type = types.attrsOf syncFolderType; };
          # Syncthing's standard ports,
          # specified here because we need it on the home manager side as well.
          port = mkOption {
            type = types.port;
            default = 22000;
          };
          discoveryPort = mkOption {
            type = types.port;
            default = 21027;
          };
        };
      };
      default = import ./sync.nix;
      readOnly = true;
      description = "Centralized Syncthing folder registry. See prefs/sync.nix.";
    };

    secrets = mkOption {
      type = types.attrsOf types.path;
      default = { };
      example = {
        wireguardPrivateKey = "/var/lib/secrets/wireguard-private-key";
      };
      description = "Named paths to out-of-band secret files on this host.";
    };
  };
}
