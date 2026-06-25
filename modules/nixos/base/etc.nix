{ config, lib, ... }:
{

  system = {
    # Mount /etc as a read-only overlayfs.
    etc.overlay.enable = true;
    etc.overlay.mutable = false;

    # Required to mount /etc on rebuilds.
    activatable = true;
  };

  # avahi's unit sets ConfigurationDirectory=avahi/services, which systemd tries
  # to create under the read-only /etc and fails the service. We ship no static
  # service files, so drop it; avahi runs fine without that directory.
  systemd.services.avahi-daemon.serviceConfig.ConfigurationDirectory =
    lib.mkIf config.services.avahi.enable
      (lib.mkForce [ ]);
}
