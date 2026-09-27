{ config, ... }:
{
  # Rootless: the daemon runs as the user, inside a user namespace, instead of
  # as root behind a socket that the docker group can reach. Membership in that
  # group is passwordless root (`docker run -v /:/host`).
  #
  # The price: container networking goes through rootlesskit, so it is slower
  # and does not preserve source addresses, ports below 1024 cannot be
  # published, and --privileged only gets the user's own privileges.
  #
  # Nothing is migrated from the rootful daemon: the data root is now
  # ~/.local/share/docker, and the images and volumes under /var/lib/docker
  # stay behind. Remove that directory once nothing in it is needed.
  virtualisation.docker = {
    enable = false;
    rootless = {
      enable = true;
      # Point DOCKER_HOST at the user's daemon, so the CLI finds it.
      setSocketVariable = true;
    };
  };

  # The daemon is a user unit, so it and its containers would stop at logout.
  # Lingering keeps the user's systemd instance, and so the daemon, running
  # from boot on.
  users.users.${config.prefs.user.name}.linger = true;
}
