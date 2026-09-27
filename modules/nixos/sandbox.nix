# Baseline systemd sandbox for the small helper units the service modules and
# the hosts define (provisioning oneshots, sync timers, normalizers).
#
# Units merge their own settings into this attrset with //. Exported from the
# flake as lib.sandbox, which is how modules and hosts alike get at it.
#
# No network by default: unix sockets only. A unit that talks over loopback or
# beyond adds its address families back, along with the IPAddressAllow or
# PrivateNetwork that fits it.
{
  # No capabilities, no way to gain any.
  CapabilityBoundingSet = "";
  NoNewPrivileges = true;
  RestrictSUIDSGID = true;

  # Filesystem: the whole system read-only, homes, devices and /tmp hidden.
  ProtectSystem = "strict";
  ProtectHome = true;
  PrivateDevices = true;
  PrivateTmp = true;
  UMask = "0077";

  # Kernel and host state.
  ProtectClock = true;
  ProtectControlGroups = true;
  ProtectHostname = true;
  ProtectKernelLogs = true;
  ProtectKernelModules = true;
  ProtectKernelTunables = true;

  # Only the unit's own processes in /proc, and none of the rest of it.
  ProtectProc = "invisible";
  ProcSubset = "pid";

  RestrictAddressFamilies = [ "AF_UNIX" ];
  RestrictNamespaces = true;
  RestrictRealtime = true;
  LockPersonality = true;
  MemoryDenyWriteExecute = true;

  # Native syscalls only: on aarch64 this closes the 32-bit compat table.
  SystemCallArchitectures = "native";
  # The lines apply in order, so a unit can append an allow-list line to take
  # a single group back (++ [ "@chown" ]) and keep the rest denied.
  SystemCallFilter = [
    "@system-service"
    "~@privileged @resources"
  ];
  # Fail a blocked syscall with EPERM instead of killing the unit.
  SystemCallErrorNumber = "EPERM";
}
