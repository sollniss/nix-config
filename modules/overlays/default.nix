{ inputs }:
[
  # Override pkgs.claude-code with the always-latest build from claude-code-nix.
  inputs.claude-code.overlays.default

  # Override pkgs.helix with the always-latest build from its master branch.
  # Reference the flake's prebuilt package to get a cache hit.
  (final: prev: {
    helix = inputs.helix.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Override pkgs.picard with the 3.0 beta (nixpkgs still ships 2.x).
  # Remove once nixpkgs updates to 3.0.
  (final: prev: {
    picard = final.callPackage ./picard3.nix { };
  })
]
