{
  inputs,
  osConfig ? null,
  lib,
  ...
}:
{
  imports = [
    inputs.self.prefs
  ];
  config = lib.mkIf (osConfig != null && osConfig ? prefs) {
    prefs = osConfig.prefs;
  };
}
