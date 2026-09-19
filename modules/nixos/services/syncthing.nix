{
  config,
  lib,
  ...
}:
let
  cfg = config.prefs.hosted.sync;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  syncFolders = config.prefs.sync.folders;

  syncPort = config.prefs.sync.port; # TCP and QUIC
  discoveryPort = config.prefs.sync.discoveryPort;

  nasEnabled = config.prefs.hosted.nas.enable;

  peers = lib.filterAttrs (name: host: name != hostname && host.syncthingId != null) network.hosts;

  # A LAN peer always answers at its static address. A VPN peer only answers
  # at its tunnel address while its tunnel is up, and is back on the LAN under
  # a DHCP address the rest of the time, so it needs both.
  addressesFor =
    host:
    let
      static = "tcp://${host.ip}:${toString syncPort}";
    in
    if host.subnet == "lan" then
      [ static ]
    else
      [
        static
        "dynamic"
      ];

  # A folder's device list.
  folderDevices =
    name:
    builtins.filter (
      h: h != hostname && network.hosts.${h}.syncthingId != null
    ) syncFolders.${name}.hosts;

  # Syncthing does not coordinate overlapping folders: a folder rooted inside
  # another would be scanned and synced by both, so every folder ignores the root of
  # any other configured folder nested beneath it, making the child the only
  # path its contents sync through.
  nestedIgnores =
    path:
    map (child: "/" + lib.removePrefix (path + "/") child) (
      builtins.filter (child: child != path && lib.hasPrefix (path + "/") child) (
        lib.attrValues cfg.folders
      )
    );
in
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;

      # The shared firewall renderer below opens the ports subnet-only;
      # openDefaultPorts would open them to everyone.
      openDefaultPorts = false;

      settings = {
        options = {
          # LAN and VPN only.
          globalAnnounceEnabled = false;
          localAnnounceEnabled = true;
          relaysEnabled = false;
          natEnabled = false;
          # Don't submit any anonymous usage data.
          urAccepted = -1;

          listenAddresses = [
            "tcp://:${toString syncPort}"
            "quic://:${toString syncPort}"
          ];
          localAnnouncePort = discoveryPort;
          localAnnounceMCAddr = "[ff12::8384]:${toString discoveryPort}";
        };

        devices = lib.mapAttrs (name: host: {
          id = host.syncthingId;
          addresses = addressesFor host;
        }) peers;

        folders = lib.mapAttrs (name: path: {
          inherit path;
          id = syncFolders.${name}.id;
          devices = folderDevices name;
          type =
            if lib.elem hostname syncFolders.${name}.untrusted then
              "receiveencrypted"
            else if lib.elem hostname syncFolders.${name}.receiveOnly then
              "receiveonly"
            else
              "sendreceive";
          ignorePatterns = nestedIgnores path;
          # Don't sync modes in either direction.
          ignorePerms = true;
        }) cfg.folders;
      };
    }
    # Run as the share's owner when the NAS lives on this host.
    // lib.optionalAttrs nasEnabled {
      user = "nas";
      group = "nas";
    };

    # The upstream module only creates its state directory for the default
    # syncthing user (via createHome), so with the user overridden above the
    # database and keys would have nowhere to go.
    systemd.tmpfiles.settings.syncthing.${config.services.syncthing.dataDir}.d = {
      user = config.services.syncthing.user;
      group = config.services.syncthing.group;
      mode = "0700";
    };

    # Pre-create the folder roots: left to Syncthing they come out 0700,
    # which on the NAS share would lock the group (Immich) out of everything
    # synced into them. 2770 is the share's directory convention.
    systemd.tmpfiles.settings.syncthing-folders = lib.mapAttrs' (
      name: path:
      lib.nameValuePair path {
        d = {
          user = config.services.syncthing.user;
          group = config.services.syncthing.group;
          mode = "2770";
        };
      }
    ) cfg.folders;

    # The folders live on nofail mounts, with the disk missing,
    # don't start and quietly resync everything onto the SD card underneath the mountpoint.
    systemd.services.syncthing.unitConfig.RequiresMountsFor = lib.attrValues cfg.folders;

    # Sync traffic and discovery from the known subnets only.
    prefs.hosted.subnetOnlyPorts = {
      tcp = [ syncPort ];
      udp = [
        syncPort
        discoveryPort
      ];
    };
  };
}
