{ config, lib, ... }:
{
  # Avahi is not enabled here but pulled in by other modules (COSMIC enables
  # it), and upstream opens 5353/udp on every interface. mDNS is link-local by
  # design: confine it to the known subnets like every other port on these
  # hosts. Printer discovery is all it is used for (CUPS itself only listens
  # on localhost).
  config = lib.mkIf config.services.avahi.enable {
    services.avahi.openFirewall = false;
    prefs.hosted.subnetOnlyPorts.udp = [ 5353 ];
  };
}
