{ lib, ... }:
{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # COSMIC turns both of these on by default. The scheduler drags in
  # bcc -> clang (~1GB) for execsnoop, and system76-power only does anything
  # useful on System76 hardware.
  services.system76-scheduler.enable = lib.mkForce false;
  hardware.system76.power-daemon.enable = lib.mkForce false;

  # COSMIC used to default this on, then swapped it for system76-power.
  # Without it nothing backs the power profile switcher.
  services.power-profiles-daemon.enable = true;
}
