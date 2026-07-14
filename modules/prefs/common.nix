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
      dns = {
        enable = mkEnableOption "dnscrypt-proxy encrypted DNS resolver.";

        cloaking = mkOption {
          type = types.attrsOf types.str;
          default = { };
          example = {
            "calendar.pi" = "192.168.1.101";
          };
          description = ''
            Names the hosted resolver answers itself, mapped to a fixed address.
            Services hosted here register their own name so LAN and VPN clients
            can reach them by name. Ignored when dns.enable is false.
          '';
        };
      };
      dhcp.enable = mkEnableOption "systemd-networkd DHCP server for the LAN, pointing clients at this host for DNS.";
      calendar.enable = mkEnableOption "SOGo web calendar and task manager.";
      share = {
        enable = mkEnableOption "Samba file share over SMB3, reachable from the LAN and the VPN.";

        path = mkOption {
          type = types.path;
          default = "/srv/share";
          example = "/mnt/share";
          description = ''
            Directory exported over SMB. There is one account and one share, so
            everyone who can log in sees and edits the same files, all of them
            owned by the same user. The default lives on the root filesystem,
            which on the Pi is the SD card: point this at external storage
            before putting anything in it.

            When this path is also a fileSystems entry, the share only comes up
            once that filesystem is mounted.
          '';
        };
      };
      photos = {
        enable = mkEnableOption "Immich photo and video library.";

        mediaLocation = mkOption {
          type = types.path;
          default = "/var/lib/immich";
          example = "/mnt/photos";
          description = ''
            Directory holding the Immich library (originals, thumbnails, database
            backups). The default lives on the root filesystem, which on the Pi is
            the SD card: point this at external storage before uploading anything
            substantial.
          '';
        };
      };
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
