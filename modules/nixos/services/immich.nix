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

      # Disable face detection and smart (CLIP) search.
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
      }
      // lib.optionalAttrs (cfg.externalLibrary != null) {
        library = {
          # Rescan the external library every 15 minutes so files added to it
          # (for example over the NAS share) show up on their own within that
          # window. This is the mechanism we rely on: Immich's filesystem
          # watcher below is a no-op in this version (it attaches no inotify
          # watches), so the periodic scan is what actually picks up new files.
          scan = {
            enabled = true;
            cronExpression = "*/15 * * * *";
          };
          # Best-effort near-instant path; harmless if it starts working in a
          # future release. Until then the scan above does the job.
          watch.enabled = true;
        };
      };
    };

    # The database and the vector extensions are set up by the upstream module;
    # it connects over the unix socket, so, like SOGo, it needs no TCP listener.
    # Harmless to state twice: both services force the same value.
    services.postgresql.settings.listen_addresses = lib.mkForce "";

    # The upstream module only tightens the permissions of an existing media
    # directory ("e"), which is enough for the default location because systemd
    # creates that one as the service's StateDirectory. A mediaLocation on
    # external storage has to be created, so replace that rule with a "d" to
    # also create the directory when missing.
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

    # Immich's storage, and the external library when set, both live on the USB
    # SSD. Don't start the server until they are mounted: the mounts are nofail,
    # so a missing disk would otherwise leave Immich writing to the SD card.
    systemd.services.immich-server.unitConfig.RequiresMountsFor =
      [ cfg.mediaLocation ]
      ++ lib.optional (cfg.externalLibrary != null) cfg.externalLibrary;

    # Register the external library over the API, the same pattern as the
    # account above: Immich has no declarative option for it. Idempotent, so it
    # is a no-op once a library already imports this path.
    systemd.services.immich-external-library = lib.mkIf (cfg.externalLibrary != null) {
      description = "Immich external library registration";
      after = [ "immich-account.service" ];
      requires = [ "immich-account.service" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = [ cfg.externalLibrary ];
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
        path=${lib.escapeShellArg cfg.externalLibrary}

        # immich-server accepts connections only after it has migrated the
        # database, which on the first boot is not quick.
        for _ in $(seq 1 150); do
          if curl -fsS -o /dev/null "$api/server/ping"; then
            break
          fi
          sleep 2
        done

        token="$(curl -fsS -X POST "$api/auth/login" \
          -H 'Content-Type: application/json' \
          --data ${lib.escapeShellArg (builtins.toJSON {
            inherit (account) email password;
          })} | jq -r .accessToken)"
        auth="Authorization: Bearer $token"

        # Already registered? Match on the import path so re-runs are no-ops.
        if curl -fsS "$api/libraries" -H "$auth" \
             | jq -e --arg p "$path" 'any(.[]; .importPaths | index($p))' >/dev/null; then
          exit 0
        fi

        owner="$(curl -fsS "$api/users/me" -H "$auth" | jq -r .id)"

        library="$(curl -fsS -X POST "$api/libraries" -H "$auth" \
          -H 'Content-Type: application/json' \
          --data "$(jq -nc --arg o "$owner" --arg p "$path" \
            '{ownerId: $o, name: "NAS photos", importPaths: [$p]}')" \
          | jq -r .id)"

        curl -fsS -o /dev/null -X POST "$api/libraries/$library/scan" -H "$auth"

        echo "Registered external library at $path."
      '';
    };

    # Mirror the external library's folder tree into albums: one album per
    # directory, named by its path relative to the library root (so
    # photos/2024/Italy becomes album "2024/Italy"). Immich has no native
    # folder-to-album feature, so this runs over the API on a timer. It is
    # additive and idempotent — it creates missing albums and adds new photos to
    # them, and never deletes; moving a file between folders leaves it in the
    # old album until removed by hand.
    systemd.timers.immich-album-sync = lib.mkIf (cfg.externalLibrary != null) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # A few minutes after each library scan (*/15), so freshly imported
        # photos are already assets by the time this groups them.
        OnCalendar = "*:05/15";
        RandomizedDelaySec = 30;
        Persistent = true;
      };
    };

    systemd.services.immich-album-sync = lib.mkIf (cfg.externalLibrary != null) {
      description = "Sync Immich external library folders into albums";
      after = [ "immich-server.service" ];
      path = [
        pkgs.curl
        pkgs.jq
        pkgs.coreutils
      ];
      serviceConfig = {
        Type = "oneshot";
        DynamicUser = true;

        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
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
        root=${lib.escapeShellArg cfg.externalLibrary}

        for _ in $(seq 1 150); do
          if curl -fsS -o /dev/null "$api/server/ping"; then
            break
          fi
          sleep 2
        done

        token="$(curl -fsS -X POST "$api/auth/login" \
          -H 'Content-Type: application/json' \
          --data ${lib.escapeShellArg (builtins.toJSON {
            inherit (account) email password;
          })} | jq -r .accessToken)"
        auth="Authorization: Bearer $token"

        # Pull every asset (id + on-disk path), paging through the results.
        assets="$(mktemp)"
        trap 'rm -f "$assets"' EXIT
        page=1
        while [ "$page" != "null" ]; do
          resp="$(curl -fsS -X POST "$api/search/metadata" -H "$auth" \
            -H 'Content-Type: application/json' \
            --data "$(jq -nc --argjson pg "$page" '{page: $pg, size: 1000}')")"
          printf '%s' "$resp" | jq -c '.assets.items[] | {id, path: .originalPath}' >> "$assets"
          page="$(printf '%s' "$resp" | jq -r '.assets.nextPage // "null"')"
        done

        # Group assets under the library root by their relative directory. Files
        # sitting directly in the root (no subfolder) get no album.
        groups="$(jq -s --arg root "$root" '
          map(select(.path | startswith($root + "/")))
          | map(.dir = (.path | ltrimstr($root + "/") | split("/") | .[:-1] | join("/")))
          | map(select(.dir != ""))
          | group_by(.dir)
          | map({name: .[0].dir, ids: map(.id)})
        ' "$assets")"

        existing="$(curl -fsS "$api/albums" -H "$auth")"

        printf '%s' "$groups" | jq -c '.[]' | while read -r g; do
          name="$(printf '%s' "$g" | jq -r .name)"
          ids="$(printf '%s' "$g" | jq -c .ids)"
          id="$(printf '%s' "$existing" | jq -r --arg n "$name" \
            'map(select(.albumName == $n)) | .[0].id // empty')"

          if [ -n "$id" ]; then
            curl -fsS -o /dev/null -X PUT "$api/albums/$id/assets" -H "$auth" \
              -H 'Content-Type: application/json' \
              --data "$(jq -nc --argjson ids "$ids" '{ids: $ids}')"
          else
            curl -fsS -o /dev/null -X POST "$api/albums" -H "$auth" \
              -H 'Content-Type: application/json' \
              --data "$(jq -nc --arg n "$name" --argjson ids "$ids" \
                '{albumName: $n, assetIds: $ids}')"
            echo "Created album \"$name\"."
          fi
        done
      '';
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
