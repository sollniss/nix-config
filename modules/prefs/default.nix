# Complete prefs schema and the canonical entry point (`import ./modules/prefs`).
# It is the shared core (./common.nix) plus the NixOS-only options: nixos.*
# (hostname/interface) and hosted.* (the services a host runs). NixOS imports
# this; home-manager imports ./common.nix and never sees either.
{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  imports = [ ./common.nix ];

  options.prefs = {
    nixos = {
      hostname = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Primary hostname for this configuration.";
      };

      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Primary network interface for this host.";
      };
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
      slaac = {
        enable = mkEnableOption ''
          A stable LAN ULA on this host, so it can be reached at an address
          that never rotates with the ISP prefix. This is what the resolver
          binds and what clients are pointed at as their IPv6 DNS server -
          a GUA would move every time the delegation changes'';

        sendRA = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Also emit Router Advertisements from this host, announcing the ULA
            prefix on-link and this host as the IPv6 resolver (RA RDNSS,
            RFC 8106), with RouterLifetime 0 so it is never treated as a
            default router.

            Only needed when the LAN's real router cannot advertise a resolver
            itself. That was true of the TP-Link Archer AX10, whose DHCPv6 DNS
            field rejects ULAs (it is a WAN field), leaving RA RDNSS from here
            as the only way to point clients at this host - and it only ever
            reached clients that honour RDNSS, so DHCPv6-only clients still
            leaked to whatever public resolver the router handed out.

            Set false when the router runs OpenWrt: odhcpd advertises the
            resolver over RA RDNSS *and* DHCPv6, which covers both kinds of
            client consistently, and one RA sender per link is easier to
            reason about than two.
          '';
        };
      };
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
          The Feishin web player as an alternative front-end for the music
          server, on its own vhost behind the shared nginx. Requires
          music.enable'';
      };

      sync = {
        enable = mkEnableOption ''
          Syncthing as an always-on sync hub: an unattended system service
          peering with the other Syncthing devices in the network topology, so
          they can sync through this host even when no two of them are online
          at the same time'';

        folders = mkOption {
          type = types.attrsOf types.path;
          default = { };
          example = {
            photos = "/srv/nas/photos/phone";
          };
          description = ''
            Folders this host participates in, as local paths keyed by their
            prefs.sync.folders name. This host must also be listed in the
            folder's hosts there, or the other participants will not share
            the folder back.
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
  };
}
