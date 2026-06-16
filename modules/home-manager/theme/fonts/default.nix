{
  pkgs,
  lib,
  config,
  ...
}:
let
  # CJK fonts for handling han-unification.
  cjk = {
    # Region used for untagged text and as the base of every generic's chain.
    defaultRegion = "JP";

    # CJK family base per generic; the region is appended.
    base = {
      sansSerif = "Noto Sans CJK";
      serif = "Noto Serif CJK";
      monospace = "Noto Sans Mono CJK";
    };

    # Language tag -> region. A rule is generated for every language whose
    # region differs from defaultRegion.
    langRegion = {
      "ja" = "JP";
      "ko" = "KR";
      "zh-cn" = "SC";
      "zh-sg" = "SC";
      "zh-tw" = "TC";
      "zh-mo" = "TC";
      "zh-hk" = "HK";
    };
  };

  # CJK family for a generic at the default region, e.g. "Noto Sans CJK JP".
  cjkDefault = generic: "${cjk.base.${generic}} ${cjk.defaultRegion}";

  # Font lists, with the default CJK font woven into each generic's chain:
  # primary/Latin fonts first, then the CJK default, then any extra fallbacks.
  sansSerif = [
    "Noto Sans"
    (cjkDefault "sansSerif")
  ];
  serif = [
    "Noto Serif"
    (cjkDefault "serif")
  ];
  monospace = [
    "JetBrains Mono"
    "Noto Sans Mono"
    (cjkDefault "monospace")
    "Symbols Nerd Font Mono"
  ];
  emoji = [
    "Noto Color Emoji"
  ];

  # Per-language CJK disambiguation (fontconfig apps only).
  # The default region stays for untagged text and its own language.
  # Text tagged with another language gets that region's glyph forms.
  cjkRules = lib.concatStringsSep "\n" (
    lib.filter (r: r != null) (
      lib.flatten (
        lib.mapAttrsToList (
          _generic: base:
          lib.mapAttrsToList (
            lang: region:
            if region == cjk.defaultRegion then
              null
            else
              ''
                <match target="pattern">
                  <test name="family"><string>${base} ${cjk.defaultRegion}</string></test>
                  <test name="lang" compare="contains"><string>${lang}</string></test>
                  <edit name="family" mode="prepend" binding="strong"><string>${base} ${region}</string></edit>
                </match>''
          ) cjk.langRegion
        ) cjk.base
      )
    )
  );
in
{
  imports = [
    ./wezterm.nix
  ];

  # Font families, so sibling modules (./wezterm.nix) can build from one source.
  # wezterm-specific derivations live in ./wezterm.nix.
  options.theme.fonts = lib.mkOption {
    type = lib.types.attrsOf (lib.types.listOf lib.types.str);
    readOnly = true;
    internal = true;
    description = "Font families per generic (monospace, sansSerif, serif, emoji).";
  };

  config = lib.mkMerge [
    {
      theme.fonts = {
        inherit
          monospace
          sansSerif
          serif
          emoji
          ;
      };
    }

    (lib.mkIf config.prefs.profile.graphical.enable {
      home.packages = with pkgs; [
        # Default fonts.
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        jetbrains-mono
        nerd-fonts.symbols-only
      ];

      fonts.fontconfig = {
        enable = true;
        #hinting.enable = true;
        #antialias = true;

        defaultFonts = {
          inherit
            monospace
            sansSerif
            serif
            emoji
            ;
        };
      };

      # Zed fonts, derived from the fontconfig defaults above.
      programs.zed-editor.userSettings = {
        ui_font_family = lib.head sansSerif;
        ui_font_fallbacks = lib.tail sansSerif;
        buffer_font_family = lib.head monospace;
        buffer_font_fallbacks = lib.tail monospace;
        # Disable programming ligatures (calt = contextual alternates).
        buffer_font_features = {
          calt = false;
        };
      };

      # CJK language disambiguation rules (see cjkRules above).
      # High number so it runs after fontconfig's generic-family expansion.
      xdg.configFile."fontconfig/conf.d/99-cjk-lang.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
        ${cjkRules}
        </fontconfig>
      '';
    })
  ];
}
