{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  hasHost = network.hosts ? ${hostname};
  self = if hasHost then network.hosts.${hostname} else null;

  buildTargets = lib.filterAttrs (_: h: h.builder == hostname) network.hosts;
  isBuildServer = hasHost && buildTargets != { };

  hasBuilder = hasHost && self.builder != null;
  builder = if hasBuilder then network.hosts.${self.builder} else null;
in
{
  config = lib.mkMerge [
    # Builder: emulate foreign platforms and sign store paths.
    (lib.mkIf isBuildServer {
      boot.binfmt.emulatedSystems =
        let
          targetPlatforms = lib.mapAttrsToList (_: h: h.platform) buildTargets;
        in
        builtins.filter (p: p != config.nixpkgs.hostPlatform.system) targetPlatforms;

      # Sign store paths so remote hosts trust them.
      nix.settings.secret-key-files = [ config.prefs.secrets.nixSigningKey ];
    })

    # Target: trust the builder's signing key.
    (lib.mkIf hasBuilder {
      nix.settings.trusted-public-keys = [ builder.signingKey ];
    })
  ];
}
