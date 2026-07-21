{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.prefs.hosted.music;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "feishin.pi";
  # Identity nginx asserts towards navidrome; keep in sync with ./navidrome.nix.
  username = "music";

  # Host-side navidrome socket, see ./navidrome.nix.
  socket = "/run/navidrome/navidrome.sock";

  # The nixpkgs feishin package is the Electron desktop app; webVersion builds
  # the same renderer as a static browser SPA instead. The override is not in
  # the binary cache, so the JS bundle compiles on the build host once per
  # nixpkgs bump.
  web = pkgs.feishin.override { webVersion = true; };

  # Feishin's official web-deployment hook: index.html loads settings.js
  # before the app bundle (the docker image generates it from env vars; the
  # nix build ships none). ANALYTICS_DISABLED gates an umami analytics snippet
  # in index.html that would otherwise fetch a script from the internet; the
  # SERVER_* values prefill and lock the add-server form for the rare case
  # someone opens it despite the seeded connection below.
  settingsJs = pkgs.writeText "feishin-settings.js" ''
    window.ANALYTICS_DISABLED = true;
    window.SERVER_NAME = 'navidrome';
    window.SERVER_TYPE = 'navidrome';
    window.SERVER_URL = 'http://${domain}';
    window.SERVER_LOCK = true;
  '';

  # Zero-touch connection: Feishin keeps its server list in browser
  # localStorage (zustand persist, key "store_authentication", version 2).
  # This classic script runs during document parse, before the deferred app
  # bundle reads that store, and seeds it with the navidrome instance, so no
  # browser ever sees the add-server/login form. Every credential is a decoy:
  # navidrome ignores the bearer token (/api) and the Subsonic salt/token
  # pair (/rest) whenever nginx asserts Remote-User, matching the login shim
  # below. Fields feishin attaches to the entry at runtime (features,
  # version, musicFolderId, ...) are preserved across loads.
  preconfig = pkgs.writeText "feishin-preconfig.js" ''
    (function () {
        'use strict';
        var KEY = 'store_authentication';
        var ID = 'navidrome-pi';
        try {
            var seed = {
                credential: 'u=${username}&s=shim&t=shim',
                id: ID,
                isAdmin: true,
                name: 'navidrome',
                ndCredential: 'shim',
                type: 'navidrome',
                url: window.location.origin,
                userId: 'feishin-shim',
                username: '${username}',
            };
            var stored = null;
            try { stored = JSON.parse(localStorage.getItem(KEY)); } catch (e) { }
            var state = (stored && stored.state) || {};
            if (!state.serverList) state.serverList = {};
            state.serverList[ID] = Object.assign({}, state.serverList[ID], seed);
            if (!state.currentServer || state.currentServer.id === ID) {
                state.currentServer = state.serverList[ID];
            }
            localStorage.setItem(KEY, JSON.stringify({ state: state, version: 2 }));
        } catch (e) {
            // Best effort: without the seed the add-server form still works.
        }
    })();
  '';

  # The SPA with both scripts in place. The settings.js reference is made
  # absolute on the way: the app is hash-routed today, but a relative src
  # would resolve against any future path-routed URL and fall through
  # try_files to index.html. --replace-fail makes an upstream layout change
  # fail the build instead of silently dropping the configuration.
  webRoot = pkgs.runCommand "feishin-web-configured" { } ''
    cp -r ${web} $out
    chmod -R u+w $out
    cp ${settingsJs} $out/settings.js
    cp ${preconfig} $out/preconfig.js
    substituteInPlace $out/index.html \
      --replace-fail '<script src="settings.js"></script>' \
                     '<script src="/settings.js"></script><script src="/preconfig.js"></script>'
  '';

  proxy = {
    proxyPass = "http://unix:${socket}";
    recommendedProxySettings = true;
    extraConfig = ''
      # An audio stream is consumed at playback speed, don't buffer.
      proxy_buffering off;

      # Same identity assertion as the navidrome vhost (see ./navidrome.nix):
      # proxy_set_header replaces any client-supplied value, so navidrome logs
      # every request in as ${username} and ignores whatever credentials
      # Feishin's login form sent.
      proxy_set_header Remote-User ${username};
    '';
  };
in
{
  # Only ./nginx.nix, NOT ./navidrome.nix: the hosts list service modules
  # explicitly (see hosts/*/configuration.nix), and importing navidrome.nix by
  # path here while configuration.nix pulls it in as a value via
  # services/default.nix would apply that module twice — the module system
  # cannot tell the two are the same file, and every types.lines option in it
  # (nginx extraConfig) came out duplicated, failing nginx config validation.
  imports = [ ./nginx.nix ];

  config = lib.mkIf cfg.feishin.enable {
    assertions = [
      {
        # Guards the dependency on the navidrome instance: Feishin is only a
        # front-end, without it there is nothing to serve.
        assertion = cfg.enable;
        message = ''
          prefs.hosted.music.feishin.enable requires prefs.hosted.music.enable:
          Feishin is only a web front-end for the navidrome instance hosted here.
        '';
      }
    ];

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        # The SPA itself: prebuilt static files straight from the store.
        root = webRoot;
        locations."/".extraConfig = ''
          # Client-side routing: unknown paths are app routes, not files.
          try_files $uri $uri/ /index.html;
        '';

        # Same-origin view of the navidrome API. Feishin is configured with
        # http://${domain} as its server URL, so the browser never makes a
        # cross-origin request and no CORS setup is needed anywhere. /auth and
        # /api are navidrome's native API (Feishin's primary protocol), /rest
        # the Subsonic API used for streaming and cover art, /ping the health
        # check. None of these prefixes collide with Feishin's app routes or
        # asset paths.
        locations."/auth" = proxy;
        locations."/api" = proxy;
        locations."/rest" = proxy;
        locations."/ping" = proxy;

        # Navidrome's /auth/login is the one endpoint header auth does not
        # cover: it always validates the submitted password against the
        # database, and the auto-created ${username} account only has a random
        # never-known one (see ./navidrome.nix). Feishin's login flow needs the
        # endpoint to succeed, so nginx answers it directly with the exact
        # shape Feishin validates (its zod schema: id, isAdmin, name,
        # subsonicSalt, subsonicToken, token, username). Every token in it is
        # a decoy: navidrome ignores both the bearer token (/api) and the
        # Subsonic salt/token pair (/rest) whenever the Remote-User header is
        # present, so the values are never checked by anyone. The decoy id is
        # only ever echoed back by Feishin in user-scoped requests; navidrome
        # derives ownership from the asserted identity, not from it.
        #
        # Consequence, by design: the login form accepts anything — the same
        # trust model as the navidrome vhost, where anyone who can reach nginx
        # is ${username}.
        locations."= /auth/login".extraConfig = ''
          default_type application/json;
          return 200 '{"id":"feishin-shim","isAdmin":true,"name":"${username}","subsonicSalt":"shim","subsonicToken":"shim","token":"shim","username":"${username}"}';
        '';
      };
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
