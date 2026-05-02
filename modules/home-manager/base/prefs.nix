{
  inputs,
  osConfig ? null,
  lib,
  ...
}:
let
  hasOsPrefs = osConfig != null && osConfig ? prefs;
  inheritedPrefs = if hasOsPrefs then removeAttrs osConfig.prefs [ "network" ] else { };
in
{
  imports = [
    inputs.self.prefs
  ];

  config = lib.mkIf hasOsPrefs {
    prefs = lib.mkDefault inheritedPrefs;
  };
}
