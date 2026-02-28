{ ... }:
{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    # FIXME: remove once https://github.com/NixOS/nixpkgs/issues/493679 is fixed upstream.
    # picosvg tests fail due to floating-point precision, blocking jetbrains-mono build.
    # https://nixpkgs-tracker.ocfox.me/?pr=493376
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (python-final: python-prev: {
          picosvg = python-prev.picosvg.overridePythonAttrs (oldAttrs: {
            doCheck = false;
          });
        })
      ];
    })

    # FIXME: remove once https://github.com/NixOS/nixpkgs/pull/493604 lands in unstable.
    # anki: add missing qt6.qtwebengine to buildInputs.
    # https://nixpkgs-tracker.ocfox.me/?pr=493604
    (final: prev: {
      anki = prev.anki.overridePythonAttrs (oldAttrs: {
        buildInputs = (oldAttrs.buildInputs or [ ]) ++ [ final.qt6.qtwebengine ];
      });
    })
  ];
}
