{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = network.hosts.${hostname};

  buildTargets = lib.filterAttrs (_: h: (h.builder or null) == hostname) network.hosts;
  isBuildServer = buildTargets != { };

  hasBuilder = (self.builder or null) != null;
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
      # sudo nix-store --generate-binary-cache-key nixos-desktop /etc/nix/signing-key.private /etc/nix/signing-key.public
      nix.settings.secret-key-files = [ "/etc/nix/signing-key.private" ];
    })

    # Target: trust the builder's signing key.
    (lib.mkIf hasBuilder {
      nix.settings.trusted-public-keys = [ builder.signingKey ];
    })
  ];
}
