{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  options.meta.profile = {
    username = mkOption {
      type = types.str;
      description = "Primary username for this configuration (used across NixOS/Home Manager).";
    };

    hostname = mkOption {
      type = types.str;
      description = "Primary hostname for this configuration (used across NixOS modules).";
    };

    graphical = {
      enable = mkEnableOption "Graphical profile capability flag (do not use directly yet).";
    };
  };
}
