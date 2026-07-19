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

  keyFile = config.prefs.secrets.immichApiKey;

  # Sandbox settings shared by every provisioning unit below.
  # Each service merges its own settings (and any deviations) on top with //.
  hardening = {
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

        # Reaches out to github.com from the server on a timer; no browser or LAN
        # feature depends on it, so keep it off.
        newVersionCheck.enabled = false;

        # The map view is enabled deliberately, with the trade-off that every
        # browser opening the app fetches map tiles from Immich's CDN over the
        # internet (the tiles are the only piece here that leaves the LAN).
        map.enabled = true;

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

    # Immich persists metadata edits (GPS, description) for external-library
    # assets to an XMP sidecar written next to the original. The NAS pool is
    # owned by nas:nas (mode 2770), so the immich user needs the nas group to
    # create those sidecars; without it, edits silently revert.
    users.users.${config.services.immich.user}.extraGroups =
      lib.optional config.prefs.hosted.nas.enable "nas";

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

    # immich-account's ReadWritePaths refuses to start the unit while the
    # secrets directory is missing, which it is on a first boot.
    systemd.tmpfiles.settings.immich.${dirOf keyFile}.d = {
      user = "root";
      group = "root";
      mode = "0755";
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
    # The same run then generates an admin API key and files it 0400 root:root with
    # the host's other secrets. The sibling immich-* services authenticate with
    # that key (via LoadCredential) instead of logging in.
    systemd.services.immich-account = {
      description = "Immich joint account registration";
      after = [ "immich-server.service" ];
      requires = [ "immich-server.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        pkgs.curl
        pkgs.jq
      ];
      serviceConfig = hardening // {
        Type = "oneshot";
        RemainAfterExit = true;

        # Root rather than DynamicUser, unlike the siblings: the key file is
        # created 0400 root:root next to the hand-installed secrets, which a
        # dynamic user could neither create there nor chown.
        ReadWritePaths = [ (dirOf keyFile) ];
      };
      script = ''
        set -euo pipefail

        api="http://127.0.0.1:${toString port}/api"
        key_file=${lib.escapeShellArg keyFile}

        # Account and key are provisioned together, so an existing (non-empty)
        # key means there is nothing left to do.
        if [ -s "$key_file" ]; then
          exit 0
        fi

        # immich-server accepts connections only after it has migrated the
        # database, which on the first boot is not quick. Fails the unit here,
        # with curl's error, if the server is still not up after ~5 minutes.
        curl -fsS --retry 150 --retry-delay 2 --retry-all-errors \
          -o /dev/null "$api/server/ping"

        if [ "$(curl -fsS "$api/server/config" | jq -r .isInitialized)" = false ]; then
          curl -fsS -o /dev/null -X POST "$api/auth/admin-sign-up" \
            -H 'Content-Type: application/json' \
            --data ${lib.escapeShellArg (builtins.toJSON account)}
          echo "Registered ${account.email}."
        fi

        # The one place the password is used after sign-up. Should this ever
        # have to run again (key file lost) after the password was changed in
        # the UI, this login fails. Generate a new key in the UI instead
        # (Account Settings -> API Keys) and install it by hand:
        #   install -m0400 /dev/stdin "$key_file"
        token="$(curl -fsS -X POST "$api/auth/login" \
          -H 'Content-Type: application/json' \
          --data ${
            lib.escapeShellArg (
              builtins.toJSON {
                inherit (account) email password;
              }
            )
          } | jq -r .accessToken)"

        # jq -e fails on a missing .secret, and the guard above retries a run
        # that left an empty file behind.
        curl -fsS -X POST "$api/api-keys" \
          -H "Authorization: Bearer $token" \
          -H 'Content-Type: application/json' \
          --data '{"name": "NixOS provisioning", "permissions": ["all"]}' \
          | jq -jre .secret | install -m0400 /dev/stdin "$key_file"

        # The login above opened a session; provisioning should leave none.
        curl -fsS -o /dev/null -X POST "$api/auth/logout" \
          -H "Authorization: Bearer $token"

        echo "Provisioned API key at $key_file."
      '';
    };

    # Enable the Folders and Tags features on the joint account. These are
    # per-user preferences (Account Settings -> Features), not server system
    # config, so they cannot go in services.immich.settings and instead ride the
    # same API pattern as the account and library above. updateMyPreferences is a
    # partial update, so sending only these two leaves the rest untouched. It
    # is a plain set and safe to re-run on every boot.
    systemd.services.immich-preferences = {
      description = "Immich joint account feature preferences";
      after = [ "immich-account.service" ];
      requires = [ "immich-account.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.curl ];
      serviceConfig = hardening // {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        LoadCredential = [ "api-key:${keyFile}" ];
      };
      script = ''
        set -euo pipefail

        api="http://127.0.0.1:${toString port}/api"

        # Wait for immich-server to accept connections; fails the unit here,
        # with curl's error, if it is still not up after ~5 minutes.
        curl -fsS --retry 150 --retry-delay 2 --retry-all-errors \
          -o /dev/null "$api/server/ping"

        # API-key auth.
        auth="x-api-key: $(cat "$CREDENTIALS_DIRECTORY/api-key")"

        curl -fsS -o /dev/null -X PUT "$api/users/me/preferences" -H "$auth" \
          -H 'Content-Type: application/json' \
          --data ${
            lib.escapeShellArg (
              builtins.toJSON {
                folders = {
                  enabled = true;
                  sidebarWeb = true;
                };
                tags = {
                  enabled = true;
                  sidebarWeb = true;
                };
              }
            )
          }

        echo "Enabled Folders and Tags for ${account.email}."
      '';
    };

    # Immich's storage, and the external library when set, both live on the USB
    # SSD. Don't start the server until they are mounted: the mounts are nofail,
    # so a missing disk would otherwise leave Immich writing to the SD card.
    systemd.services.immich-server.unitConfig.RequiresMountsFor = [
      cfg.mediaLocation
    ]
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
      serviceConfig = hardening // {
        Type = "oneshot";
        RemainAfterExit = true;
        DynamicUser = true;
        LoadCredential = [ "api-key:${keyFile}" ];
      };
      script = ''
        set -euo pipefail

        api="http://127.0.0.1:${toString port}/api"
        path=${lib.escapeShellArg cfg.externalLibrary}

        # immich-server accepts connections only after it has migrated the
        # database, which on the first boot is not quick. Fails the unit here,
        # with curl's error, if the server is still not up after ~5 minutes.
        curl -fsS --retry 150 --retry-delay 2 --retry-all-errors \
          -o /dev/null "$api/server/ping"

        # API-key auth.
        auth="x-api-key: $(cat "$CREDENTIALS_DIRECTORY/api-key")"

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
    # photos/2024/Italy becomes album "2024/Italy"). A leading date prefix on
    # each path segment is stripped from the album name. "20241120-27 Paris"
    # and "20241123 - New York" become "Paris" and "New York".
    # Immich has no native folder-to-album feature, so this runs  over the API
    # on a timer. It is additive and idempotent: moving a file between folders
    # leaves it in the old album until removed by hand.
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
      # immich-account also provides the api-key credential, which it stays active
      # (RemainAfterExit), so the requires is satisfied whenever the timer
      # fires and never re-runs the provisioning.
      after = [
        "immich-server.service"
        "immich-account.service"
      ];
      requires = [ "immich-account.service" ];
      path = [
        pkgs.curl
        pkgs.jq
        pkgs.coreutils
      ];
      serviceConfig = hardening // {
        Type = "oneshot";
        DynamicUser = true;
        LoadCredential = [ "api-key:${keyFile}" ];
        PrivateTmp = true;
      };
      script = ''
        set -euo pipefail

        api="http://127.0.0.1:${toString port}/api"
        root=${lib.escapeShellArg cfg.externalLibrary}

        # Wait for immich-server to accept connections; fails the unit here,
        # with curl's error, if it is still not up after ~5 minutes.
        curl -fsS --retry 150 --retry-delay 2 --retry-all-errors \
          -o /dev/null "$api/server/ping"

        auth="x-api-key: $(cat "$CREDENTIALS_DIRECTORY/api-key")"

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
        #
        # The album name is the relative directory with a leading "YYYYMMDD"
        # (optionally a "-DD" or "-MMDD" range end) and its " - " or " "
        # separator dropped from each path segment; a segment without a date
        # prefix is left as-is.
        #
        # Two folders whose names collide after that stripping (e.g.
        # "20210913 - Paris" and "20260224 - Paris") would otherwise merge into
        # one album, so those — and only those — get the shortest date suffix
        # that tells them apart: "(YYYY)" when the years differ, "(YYYY-MM)" when
        # two share a year, "(YYYY-MM-DD)" when they share a month. A name that is
        # already unique stays bare.
        groups="$(jq -s --arg root "$root" '
          def undate: sub("^[0-9]{8}(-[0-9]{2,4})?( +- +| +)"; "");
          map(select(.path | startswith($root + "/")))
          | map(.dir = (.path | ltrimstr($root + "/") | split("/") | .[:-1] | join("/")))
          | map(select(.dir != ""))
          | group_by(.dir)
          | map({
              base: (.[0].dir | split("/") | map(undate) | join("/")),
              d: (.[0].dir | split("/")[0]
                  | (capture("^(?<y>[0-9]{4})(?<m>[0-9]{2})(?<day>[0-9]{2})") // null)),
              ids: map(.id)
            })
          | [ group_by(.base)[]
              | . as $set
              | $set[]
              | . as $g
              | { name: (
                    if ($set | length) == 1 or $g.d == null then $g.base
                    elif ([ $set[] | select(.d.y == $g.d.y) ] | length) == 1
                      then "\($g.base) (\($g.d.y))"
                    elif ([ $set[] | select(.d.y == $g.d.y and .d.m == $g.d.m) ] | length) == 1
                      then "\($g.base) (\($g.d.y)-\($g.d.m))"
                    else "\($g.base) (\($g.d.y)-\($g.d.m)-\($g.d.day))"
                    end
                  ),
                  ids: $g.ids }
            ]
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
            new="$(curl -fsS -X POST "$api/albums" -H "$auth" \
              -H 'Content-Type: application/json' \
              --data "$(jq -nc --arg n "$name" --argjson ids "$ids" \
                '{albumName: $n, assetIds: $ids}')")"
            # New albums default to newest-first (desc), which makes a trip read
            # in reverse. Flip to oldest-first so the photos run chronologically.
            # Only at creation, so a manual per-album order set later in the UI is
            # left untouched.
            curl -fsS -o /dev/null -X PATCH "$api/albums/$(printf '%s' "$new" | jq -r .id)" \
              -H "$auth" -H 'Content-Type: application/json' \
              --data '{"order": "asc"}'
            echo "Created album \"$name\"."
          fi
        done
      '';
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
