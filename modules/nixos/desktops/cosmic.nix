{ lib, pkgs, ... }:
{
  services.displayManager.cosmic-greeter.enable = true;
  services.desktopManager.cosmic.enable = true;

  # The on-screen keyboard is in the module's corePkgs list, which trips an
  # eval warning; there is no touchscreen here, and COSMIC runs fine without it.
  environment.cosmic.excludePackages = [ pkgs.cosmic-osk ];
  services.desktopManager.cosmic.showExcludedPkgsWarning = false;

  # COSMIC turns both of these on by default. The scheduler drags in
  # bcc -> clang (~1GB) for execsnoop, and system76-power only does anything
  # useful on System76 hardware.
  services.system76-scheduler.enable = lib.mkForce false;
  hardware.system76.power-daemon.enable = lib.mkForce false;

  # The /etc image NixOS loop-mounts. After a switch the new image's loop
  # device carries no mount udisks can see, so the file manager lists it as a
  # "45 KB Volume".
  services.udev.extraRules = ''
    SUBSYSTEM=="block", KERNEL=="loop*", ATTR{loop/backing_file}=="*-etc-metadata.erofs", ENV{UDISKS_IGNORE}="1"
  '';

  # COSMIC used to default this on, then swapped it for system76-power.
  # Without it nothing backs the power profile switcher.
  services.power-profiles-daemon.enable = true;

  # cosmic-osd is the polkit agent and registers only at startup, so after
  # polkitd restarts (which a rebuild does whenever polkit's package changes)
  # the new polkitd knows no agent and every polkit prompt fails until
  # re-login (https://github.com/pop-os/cosmic-osd/issues/233).
  # cosmic-session respawns cosmic-osd when it is killed, so kill it once
  # polkitd is down; the respawned process registers with the new instance.
  # The hook is PartOf polkit.service, so it is stopped and started with it,
  # and Before= it, so it is stopped only after polkitd has stopped.
  # Otherwise the respawn could register with the old instance just before
  # it went away.
  # (The same trick does not work for cosmic-settings-daemon: it exits
  # cleanly on SIGTERM, so cosmic-session does not respawn it.)
  systemd.services.cosmic-osd-polkit-reconnect = {
    description = "Restart cosmic-osd along with polkit.service";
    wantedBy = [ "polkit.service" ];
    partOf = [ "polkit.service" ];
    before = [ "polkit.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.coreutils}/bin/true";
      # pkill exits 1 when nothing matched, e.g. at boot or shutdown.
      ExecStop = "-${pkgs.procps}/bin/pkill --exact --full cosmic-osd";
    };
  };
}
