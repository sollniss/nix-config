{ inputs }:
[
  # Override pkgs.claude-code with the always-latest build from claude-code-nix.
  inputs.claude-code.overlays.default

  # Override pkgs.helix with the always-latest build from its master branch.
  # Reference the flake's prebuilt package to get a cache hit.
  (final: prev: {
    helix = inputs.helix.packages.${prev.stdenv.hostPlatform.system}.default;
  })

  # Qt 6.12's uic rejects class names with a leading "::" in .ui files,
  # which breaks the mozc build. Remove once nixpkgs/upstream fixes it.
  (final: prev: {
    mozc = prev.mozc.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace src/gui/dictionary_tool/dictionary_tool.ui \
          --replace-fail '::mozc::gui::DictionaryContentTableWidget' 'mozc::gui::DictionaryContentTableWidget'
      '';
    });
  })
]
