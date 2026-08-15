{
  inputs,
  osConfig ? null,
  lib,
  ...
}:
let
  hasOsPrefs = osConfig != null && osConfig ? prefs;
  # Drop NixOS-only namespaces: `network` and `sync` are readOnly constants
  # both sides already get from the shared module, and `nixos.*` isn't
  # declared in HM.
  inheritedPrefs =
    if hasOsPrefs then
      removeAttrs osConfig.prefs [
        "network"
        "sync"
        "nixos"
      ]
    else
      { };
in
{
  imports = [
    inputs.self.modules.homeManager.prefs
  ];

  config = lib.mkIf hasOsPrefs {
    prefs = lib.mkDefault inheritedPrefs;
  };
}
