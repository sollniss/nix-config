# Draft of a `programs.picard` module meant to be upstreamed to home-manager
# as modules/programs/picard/. Kept free of anything specific to this repo.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.picard;
  jsonFormat = pkgs.formats.json { };

  managedSettings = jsonFormat.generate "picard-managed-settings.json" {
    inherit (cfg) settings;
  };

  # Loaded at interpreter startup through nixpkgs' sitecustomize, which runs
  # site.addsitedir() on every NIX_PYTHONPATH entry and so processes `.pth`
  # files. See hm_picard.py for what it patches.
  shim = pkgs.runCommand "hm-picard-shim" { } ''
    mkdir -p $out
    cp ${./hm_picard.py} $out/hm_picard.py
    echo "import hm_picard" > $out/hm_picard.pth
  '';

  wrappedPackage = pkgs.symlinkJoin {
    name = "${cfg.package.name}-hm";
    paths = [ cfg.package ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for prog in picard picard-cli; do
        if [ -e "$out/bin/$prog" ]; then
          wrapProgram "$out/bin/$prog" \
            --prefix NIX_PYTHONPATH : ${shim} \
            --set HM_PICARD_MANAGED_SETTINGS ${managedSettings}
        fi
      done
    '';
    inherit (cfg.package) meta;
  };
in
{
  meta.maintainers = [ ];

  options.programs.picard = {
    enable = lib.mkEnableOption "MusicBrainz Picard";

    package = lib.mkPackageOption pkgs "picard" { nullable = true; };

    finalPackage = lib.mkOption {
      type = with lib.types; nullOr package;
      readOnly = true;
      description = "Resulting Picard package, wrapped to enforce {option}`programs.picard.settings`.";
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = lib.literalExpression ''
        {
          rename_files = true;
          move_files = true;
          move_files_to = "''${config.xdg.userDirs.music}";
          windows_compatibility = true;
          caa_approved_only = true;
        }
      '';
      description = ''
        Options from the `[setting]` section of {file}`Picard.ini` to manage
        declaratively. Keys are Picard's internal option names.

        Picard.ini stays writable and is left untouched. Instead Picard is
        wrapped so that these values replace whatever is stored there,
        including values from option profiles. Writes to them are ignored, and
        the matching widgets in the Options dialog and entries in the quick
        settings menu are disabled. All other options, window state and
        profiles stay mutable.

        Unknown option names are reported in Picard's log at startup.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    programs.picard.finalPackage =
      if cfg.package == null then
        null
      else if cfg.settings == { } then
        cfg.package
      else
        wrappedPackage;

    home.packages = lib.mkIf (cfg.finalPackage != null) [ cfg.finalPackage ];
  };
}
