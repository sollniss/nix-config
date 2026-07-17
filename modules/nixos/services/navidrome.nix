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

  domain = "music.pi";
  port = 4533;

  account = {
    username = "music";
    password = "music";
  };
in
{
  imports = [ ./nginx.nix ];

  config = lib.mkIf cfg.enable {
    services.navidrome = {
      enable = true;

      # We manage firewall rules ourselves.
      openFirewall = false;

      settings = {
        Address = "127.0.0.1";
        Port = port;

        MusicFolder = cfg.musicFolder;

        # Disable stuff that accesses the internet.
        EnableExternalServices = false;
        EnableInsightsCollector = false;

        # With this on, the web UI edits the transcoding command lines, so an
        # admin session is one saved form away from running arbitrary commands
        # on this host. Off is the default; stated because it is the one
        # navidrome setting that must never flip.
        EnableTranscodingConfig = false;
      };
    };

    # Disable internet access completely.
    systemd.services.navidrome.serviceConfig = {
      IPAddressAllow = "localhost";
      IPAddressDeny = "any";
    };

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        locations."/" = {
          proxyPass = "http://127.0.0.1:${toString port}";
          recommendedProxySettings = true;
          extraConfig = ''
            # An audio stream is consumed at playback speed, don't buffer.
            proxy_buffering off;
          '';
        };
      };
    };

    # Navidrome has no declarative users, so we register the account over the API.
    # createAdmin is the only endpoint that works without credentials,
    # and only for as long as the instance has no user at all,
    # so this succeeds once on the first boot and is a no-op from then on.
    #
    # Consequently this only ever creates the account. Editing the password
    # above will not move an account that already exists: that is a UI
    # operation.
    systemd.services.navidrome-account = {
      description = "Navidrome account registration";
      after = [ "navidrome.service" ];
      requires = [ "navidrome.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.curl ];
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

        api="http://127.0.0.1:${toString port}"
        creds=${lib.escapeShellArg (builtins.toJSON account)}

        # navidrome answers /ping as soon as the HTTP server is up; the first
        # boot also kicks off the initial library scan but does not block on it.
        for _ in $(seq 1 60); do
          if curl -fsS -o /dev/null "$api/ping"; then
            break
          fi
          sleep 2
        done

        # Logging in successfully means the account already exists.
        if curl -fsS -o /dev/null -X POST "$api/auth/login" \
          -H 'Content-Type: application/json' --data "$creds"; then
          exit 0
        fi

        status=$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$api/auth/createAdmin" \
          -H 'Content-Type: application/json' --data "$creds")
        case "$status" in
          # 403 means users exist, just not with the credentials above (e.g.
          # the password was changed in the UI): leave the accounts alone.
          200) echo "Registered ${account.username}." ;;
          403) echo "Users exist already; nothing to register." ;;
          *)
            echo "createAdmin failed with HTTP $status" >&2
            exit 1
            ;;
        esac
      '';
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
