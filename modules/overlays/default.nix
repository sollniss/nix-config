{ inputs }:
[
  # Override pkgs.claude-code with the always-latest build from claude-code-nix.
  inputs.claude-code.overlays.default

  # Override pkgs.helix with the always-latest build from its master branch.
  # Reference the flake's prebuilt package to get a cache hit.
  (final: prev: {
    helix = inputs.helix.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Backport of https://github.com/NixOS/nixpkgs/pull/584713 ("anki: fix build").
  # TODO: remove once that PR has reached nixos-unstable.
  # - hatchling >= 1.32 depends on tomlkit, missing from anki's offline uv wheels.
  # - cargoSetupHook now makes zstd-sys/libsqlite3-sys use system libs via pkg-config.
  (final: prev: {
    anki = prev.anki.overrideAttrs (old: {
      nativeBuildInputs = old.nativeBuildInputs ++ [ prev.pkg-config ];
      buildInputs = old.buildInputs ++ [
        prev.sqlite
        prev.zstd
      ];
      env = old.env // {
        UV_FIND_LINKS = "${prev.runCommand "uv-wheels-with-tomlkit" { } ''
          mkdir -p $out
          ln -s ${old.env.UV_FIND_LINKS}/*.whl $out
          ln -sf ${prev.python3.pkgs.tomlkit.dist}/*.whl $out
        ''}";
      };
    });
  })
]
