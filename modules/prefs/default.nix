# Complete prefs schema and the canonical entry point (`import ./modules/prefs`).
# It is the shared core (./common.nix) plus the NixOS-only nixos.* options, which
# are only meaningful in a NixOS evaluation (hostname/interface). NixOS imports
# this; home-manager imports ./common.nix so it never sees prefs.nixos.*.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  imports = [ ./common.nix ];

  options.prefs.nixos = {
    hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary hostname for this configuration.";
    };

    interface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary network interface for this host.";
    };
  };
}
