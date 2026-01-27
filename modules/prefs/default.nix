{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.prefs = {
    user.name = mkOption {
      type = types.str;
      description = "Primary username for this configuration.";
    };

    nixos.hostname = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Primary hostname for this configuration.";
    };

    profile = {
      graphical.enable = mkEnableOption "Graphical profile capability flag.";
    };
  };
}
