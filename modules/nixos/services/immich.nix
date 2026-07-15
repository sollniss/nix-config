# Immich: self-hosted photo and video library.
#
# Shares the PostgreSQL cluster and the nginx front-end that already exist on
# this host (see ./sogo.nix and ./nginx.nix) rather than standing up its own,
# but is otherwise self-contained: enabling prefs.hosted.photos is enough, with
# or without any other hosted service.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prefs.hosted.photos;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "photos.pi";
  port = 2283;
  account = {
    email = "photos@localhost";
    name = "Photos";
    password = "photos";
  };

in
{
  imports = [ ./nginx.nix ];

  config = lib.mkIf cfg.enable {
    services.immich = {
      enable = true;

      # Loopback only: everything goes through the nginx vhost below, which is
      # where the access restrictions live. openFirewall stays off (its default)
      # so the port is never opened even if this ever binds elsewhere.
      host = "127.0.0.1";
      inherit port;
      openFirewall = false;

      mediaLocation = cfg.mediaLocation;

      # Face detection and smart (CLIP) search. The models are far too heavy for
      # this host to run alongside everything else, so the service is left off
      # and the feature is disabled server side below, otherwise every upload
      # queues a job against a machine-learning URL that answers nothing.
      machine-learning.enable = false;

      # Declaring settings makes Immich read them from a config file, which also
      # makes the corresponding admin page in the web UI read-only. Drop this
      # block to hand those settings back to the web UI.
      settings = {
        machineLearning.enabled = false;

        # Both of these reach out to the internet: a version check to github.com
        # from the server, and map tiles to Immich's CDN from every browser that
        # opens the app.
        newVersionCheck.enabled = false;
        map.enabled = false;

        # Used to build shared links, which only resolve on the LAN or over VPN.
        server.externalDomain = "http://${domain}";
      };
    };

    # The database and the vector extensions are set up by the upstream module;
    # it connects over the unix socket, so, like SOGo, it needs no TCP listener.
    # Harmless to state twice: both services force the same value.
    services.postgresql.settings.listen_addresses = lib.mkForce "";

    # The upstream module only tightens the permissions of an existing media
    # directory ("e"), which is enough for the default location because systemd
    # creates that one as the service's StateDirectory. A mediaLocation on
    # external storage has to be created, so replace that rule with a "d" —
    # same ownership and mode, but it also creates the directory when missing.
    # Two rules for one path would collide, hence the override rather than a
    # second entry.
    systemd.tmpfiles.settings.immich.${cfg.mediaLocation} = lib.mkForce {
      d = {
        user = config.services.immich.user;
        group = config.services.immich.group;
        mode = "0700";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          proxyWebsockets = true; # Immich pushes updates over a websocket.
          recommendedProxySettings = true;
          extraConfig = ''
            # Uploads are whole photos and videos: no size cap, and stream them
            # straight through instead of spooling them to the SD card first.
            client_max_body_size 0;
            proxy_request_buffering off;
            proxy_buffering off;

            # A large video upload over wifi outlasts the default 60s.
            proxy_read_timeout 600s;
            proxy_send_timeout 600s;
          '';
        };
      };
    };

    # Immich has no declarative users, and its CLI cannot create one, so the
    # account is registered over the API. admin-sign-up is the only endpoint that
    # works without credentials, and only for as long as the instance has no user
    # at all, so this succeeds once on the first boot and is a no-op from then on.
    #
    # Consequently this only ever creates the account. Changing the password
    # afterwards is not something the API lets us do without the current one, so
    # editing it above will not move an account that already exists: that is a UI
    # operation, or `immich-admin reset-admin-password` on this host.
    systemd.services.immich-account = {
      description = "Immich joint account registration";
      after = [ "immich-server.service" ];
      requires = [ "immich-server.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.curl
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;

        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateDevices = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        UMask = "0077";
      };
      script = ''
        set -euo pipefail

        api="http://127.0.0.1:${toString port}/api"

        # immich-server accepts connections only after it has migrated the
        # database, which on the first boot is not quick.
        for _ in $(seq 1 150); do
          if curl -fsS -o /dev/null "$api/server/ping"; then
            break
          fi
          sleep 2
        done

        if [ "$(curl -fsS "$api/server/config" | jq -r .isInitialized)" = true ]; then
          exit 0
        fi

        curl -fsS -o /dev/null -X POST "$api/auth/admin-sign-up" \
          -H 'Content-Type: application/json' \
          --data ${lib.escapeShellArg (builtins.toJSON account)}

        echo "Registered ${account.email}."
      '';
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
