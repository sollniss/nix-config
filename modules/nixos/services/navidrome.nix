{
  config,
  lib,
  ...
}:
let
  cfg = config.prefs.hosted.music;
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  domain = "music.pi";
  username = "music";

  # Host-side socket path. The nixpkgs module chroots navidrome into its
  # runtime directory (RootDirectory = /run/navidrome), so inside the service
  # this same socket lives at /navidrome.sock.
  socket = "/run/navidrome/navidrome.sock";
in
{
  imports = [ ./nginx.nix ];

  config = lib.mkIf cfg.enable {
    # Navidrome has no declarative users. Instead of registering an account
    # over the API, nginx asserts the identity on every request via the
    # Remote-User header; navidrome auto-creates that account on first
    # request (the first user ever becomes admin) with a random, never-used
    # password. Trust model: anyone who can reach nginx is ${username}.
    services.navidrome = {
      enable = true;

      # We manage firewall rules ourselves.
      openFirewall = false;

      settings = {
        # Path as seen from inside the service's chroot; ${socket} on the host.
        Address = "unix:/navidrome.sock";
        # Default value, but the group access above depends on it.
        UnixSocketPerm = "0660";

        ExtAuth.TrustedSources = "@";
        # Passwords are never consulted with header auth.
        # Don't offer to edit them in the UI.
        EnableUserEditing = false;

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

    # Navidrome is only reachable over the unix socket and, with the external
    # services above disabled, never needs the network itself.
    systemd.services.navidrome.serviceConfig.IPAddressDeny = "any";

    # Lets nginx connect to the 0660 socket.
    users.users.nginx.extraGroups = [ "navidrome" ];

    services.nginx = {
      enable = true;
      virtualHosts.${domain} = {
        locations."/" = {
          proxyPass = "http://unix:${socket}";
          recommendedProxySettings = true;
          extraConfig = ''
            # An audio stream is consumed at playback speed, don't buffer.
            proxy_buffering off;

            # proxy_set_header replaces any client-supplied value, so the
            # identity cannot be forged from outside. With the header present
            # navidrome also ignores Subsonic u/p/t/s parameters, so mobile
            # clients work with any password.
            proxy_set_header Remote-User ${username};
          '';
        };
      };
    };

    # Resolve ${domain} to this host for every client using the local resolver.
    prefs.hosted.dns.cloaking.${domain} = self.ip;
  };
}
