{
  inputs,
  osConfig ? null,
  lib,
  ...
}:
let
  hasOsPrefs = osConfig != null && osConfig ? prefs;
  # Drop NixOS-only namespaces: `network` is a readOnly constant both sides
  # already get from the shared module, and `nixos.*` isn't declared in HM.
  inheritedPrefs =
    if hasOsPrefs then
      removeAttrs osConfig.prefs [
        "network"
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
