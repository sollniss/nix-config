{
  config,
  lib,
  hostPlatforms ? { },
  ...
}:
{
  # Emulate systems to build for.
  # Using emulation instead of cross-compiling allows using nixpkgs-cached packages.
  config = lib.mkIf (config.prefs.buildFor != [ ]) {
    boot.binfmt.emulatedSystems =
      let
        targetSystems = map (host: hostPlatforms.${host}) config.prefs.buildFor;
      in
      builtins.filter (s: s != config.nixpkgs.hostPlatform.system) targetSystems;

    # Sign store paths so remote hosts trust them.
    # sudo nix-store --generate-binary-cache-key nixos-desktop /etc/nix/signing-key.private /etc/nix/signing-key.public
    nix.settings.secret-key-files = [ "/etc/nix/signing-key.private" ];
  };
}
