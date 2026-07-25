# Picard 3.0 beta, ported from the nixpkgs 2.x derivation
# (pkgs/by-name/pi/picard/package.nix). Main differences in 3.0:
# Qt5 -> Qt6 (PyQt6), new pygit2/tomlkit deps, dropped fasteners and
# python-dateutil, and locales are built into the package so the
# --localedir flag is gone.
{
  lib,
  stdenv,
  python313Packages,
  fetchFromGitHub,

  cacert,
  chromaprint,
  gettext,
  qt6,

  enablePlayback ? true,
  gst_all_1,

  writableTmpDirAsHomeHook,
}:

let
  pythonPackages = python313Packages;
in
pythonPackages.buildPythonApplication (finalAttrs: {
  pname = "picard";
  version = "3.0.0b7";
  pyproject = true;
  strictDeps = true;
  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "metabrainz";
    repo = "picard";
    tag = "release-${finalAttrs.version}";
    hash = "sha256-kKRYiIZUaqvoqWQbKmtvleOtR+raMcKCFxBG5mtVTXA=";
  };

  nativeBuildInputs = [
    gettext
    qt6.wrapQtAppsHook
    pythonPackages.setuptools
  ];

  buildInputs = [
    qt6.qtbase
  ]
  ++ lib.optionals (lib.meta.availableOn stdenv.hostPlatform qt6.qtwayland) [
    qt6.qtwayland
  ]
  ++ lib.optionals enablePlayback [
    qt6.qtmultimedia
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
  ];

  # Upstream pins pygit2 to ~=1.19; whatever nixpkgs ships is close enough.
  pythonRelaxDeps = [ "pygit2" ];

  dependencies =
    (with pythonPackages; [
      charset-normalizer
      discid
      markdown
      mutagen
      pygit2
      pyjwt
      pyqt6
      pyyaml
      tomlkit
    ])
    ++ [ chromaprint ];

  setupPyGlobalFlags = [
    "build"
    "--disable-autoupdate"
  ];

  nativeCheckInputs = [
    pythonPackages.pytestCheckHook
    writableTmpDirAsHomeHook
  ];
  doCheck = true;

  # pygit2 loads SSL cert locations at import time, which fails in the
  # certificate-less build sandbox.
  preCheck = ''
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  # In order to spare double wrapping, we use:
  preFixup = ''
    makeWrapperArgs+=("''${qtWrapperArgs[@]}")
  ''
  + lib.optionalString enablePlayback ''
    makeWrapperArgs+=(--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0")
  '';

  meta = {
    homepage = "https://picard.musicbrainz.org";
    changelog = "https://picard.musicbrainz.org/changelog";
    description = "Official MusicBrainz tagger (3.0 beta)";
    mainProgram = "picard";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
  };
})
