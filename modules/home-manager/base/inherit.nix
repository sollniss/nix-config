{
  osConfig ? null,
  lib,
  ...
}:
let
  hasOsConfig = osConfig != null;
  hasOsShellAliases = hasOsConfig && lib.hasAttrByPath [ "environment" "shellAliases" ] osConfig;
  inheritedShellAliases = if hasOsShellAliases then osConfig.environment.shellAliases else { };
in
{
  config = lib.mkMerge [
    (lib.mkIf hasOsShellAliases {
      home.shellAliases = lib.mapAttrs (_: lib.mkDefault) inheritedShellAliases;
    })
  ];
}
