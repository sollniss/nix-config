{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  flake = "/home/${config.prefs.user.name}/nix-config";
  hasHost = network.hosts ? ${hostname};
  self = if hasHost then network.hosts.${hostname} else null;

  buildTargets = lib.filterAttrs (_: h: (h.builder or null) == hostname) network.hosts;
  isBuildServer = hasHost && buildTargets != { };

  hasBuilder = hasHost && (self.builder or null) != null;
  builder = if hasBuilder then network.hosts.${self.builder} else null;

  deployAliases =
    let
      switchAliases = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "deploy-${name}" "sudo nixos-rebuild switch --flake ${flake}#${name} --target-host root@${host.ip}"
      ) buildTargets;

      bootAliases = lib.mapAttrs' (
        name: host:
        lib.nameValuePair "deploy-${name}-boot" "sudo nixos-rebuild boot --flake ${flake}#${name} --target-host root@${host.ip}"
      ) buildTargets;
    in
    switchAliases // bootAliases;
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

      # Convenience aliases for deploying each assigned target.
      environment.shellAliases = deployAliases;

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
