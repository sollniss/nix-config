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
      slaac.enable = mkEnableOption ''
        systemd-networkd IPv6 Router Advertisements for the LAN: announce a
        stable ULA prefix on-link (SLAAC) and this host as the IPv6 DNS server
        (RA RDNSS), so IPv6-preferring clients resolve the hosted vhosts too.
        Android picks up the RDNSS directly; Windows and other DHCPv6 clients
        need the router's WAN IPv6 DNS pointed at this host's ULA as well,
        which is a manual router step (the router owns DHCPv6, not this host)'';
      calendar.enable = mkEnableOption "SOGo web calendar and task manager.";
      nas = {
        enable = mkEnableOption "File share over SMB3 (Windows, reachable from the LAN and the VPN) and NFSv4 (Linux, exported only to the managed hosts in the network topology).";

        path = mkOption {
          type = types.path;
          default = "/srv/nas";
          example = "/mnt/nas";
          description = ''
            Directory exported over both protocols. There is one account and one
            share, so everyone who can log in sees and edits the same files, all
            of them owned by the same user, whichever protocol wrote them. The
            default lives on the root filesystem.

            When this path is also a fileSystems entry, the share only comes up
            once that filesystem is mounted.
          '';
        };
      };
      subnetOnlyPorts = {
        tcp = mkOption {
          type = types.listOf types.port;
          default = [ ];
          example = [ 22 ];
          description = ''
            TCP ports reachable only from the known subnets.
            Service modules declare their ports here instead of hand-writing
            firewall snippets; the shared renderer
            (modules/nixos/services/firewall.nix) turns the merged lists into
            nftables accept-then-drop rules.
          '';
        };
        udp = mkOption {
          type = types.listOf types.port;
          default = [ ];
          example = [ 53 ];
          description = "UDP counterpart of subnetOnlyPorts.tcp.";
        };
      };

      music = {
        enable = mkEnableOption "Navidrome music collection server and streamer.";

        musicFolder = mkOption {
          type = types.path;
          default = "/var/lib/navidrome/music";
          example = "/mnt/music";
          description = ''
            Directory holding the music library. Navidrome only ever reads it;
            files get there by other means (scp, the NAS share, ...).

            Created owned by navidrome with mode 700 when missing; a directory
            that already exists keeps its ownership and mode, and then merely
            has to be readable by the navidrome user.
          '';
        };

        feishin.enable = mkEnableOption ''
          the Feishin web player as an alternative front-end for the music
          server, on its own vhost behind the shared nginx. Requires
          music.enable'';
      };

      photos = {
        enable = mkEnableOption "Immich photo and video library.";

        mediaLocation = mkOption {
          type = types.path;
          default = "/var/lib/immich";
          example = "/mnt/photos";
          description = ''
            Directory holding the Immich library (originals, thumbnails, database
            backups).
          '';
        };

        externalLibrary = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/srv/nas/photos";
          description = ''
            Path to a directory of photos and videos managed outside Immich.
            When set, Immich indexes it as a read-only external library: files
            added to it (for example over the NAS share) show up in the timeline,
            and Immich never moves or edits the originals. Immich still keeps its
            own mediaLocation for the thumbnails and transcodes it derives.

            The Immich service user must be able to read this path.
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
