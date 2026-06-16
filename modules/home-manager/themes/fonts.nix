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

  # WezTerm only consults the system fallback after its own bundled fonts, so
  # list our system fonts explicitly to enforce them.
  weztermFonts = lib.concatMapStringsSep ", " (f: ''"${f}"'') (monospace ++ [ (lib.head emoji) ]);

  # WezTerm synthesizes any requested bold/italic a font lacks.
  # To get native-only rendering we request each variant only from fonts that
  # actually ship it.
  # Everything else resolves to its native face.
  # Native variants in our stack:
  #   - JetBrains Mono: real Bold, Italic, Bold-Italic.
  #   - Noto (mono + CJK): real weights incl. Bold, but NO italic.
  #   - Symbols Nerd Font Mono + emoji: neither bold nor italic.
  # The symbol font is the last monospace entry by convention.
  italicFonts = [ (lib.head monospace) ]; # ship a real italic face
  textFonts = lib.init monospace; # ship real weights (incl. Bold)
  bareFonts = [
    # symbols/emoji: no bold, no italic
    (lib.last monospace)
    (lib.head emoji)
  ];

  # Render the Lua font_with_fallback entries for a font_rule. `weight` (or null)
  # is applied to the text fonts; `italic` adds style="Italic" only to fonts that
  # have a native italic. Fonts left with no attributes are emitted as bare names
  # so WezTerm uses their native face instead of synthesizing the missing variant.
  mkFallback =
    {
      weight ? null,
      italic ? false,
    }:
    let
      entry =
        f:
        let
          attrs =
            (lib.optional (weight != null) ''weight = "${weight}"'')
            ++ (lib.optional (italic && builtins.elem f italicFonts) ''style = "Italic"'');
        in
        if attrs == [ ] then ''"${f}",'' else ''{ family = "${f}", ${lib.concatStringsSep ", " attrs} },'';
    in
    lib.concatStringsSep "\n" (map entry textFonts ++ map (f: ''"${f}",'') bareFonts);

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
  config = lib.mkIf config.prefs.profile.graphical.enable {
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

    # WezTerm fonts.
    programs.wezterm.extraConfig = ''
      config.font = wezterm.font_with_fallback({ ${weztermFonts} })
      config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
      config.font_rules = {
        {
          intensity = "Bold",
          italic = false,
          font = wezterm.font_with_fallback({
      ${mkFallback { weight = "Bold"; }}
          }),
        },
        {
          intensity = "Bold",
          italic = true,
          font = wezterm.font_with_fallback({
      ${mkFallback {
        weight = "Bold";
        italic = true;
      }}
          }),
        },
        {
          intensity = "Normal",
          italic = true,
          font = wezterm.font_with_fallback({
      ${mkFallback { italic = true; }}
          }),
        },
        {
          intensity = "Half",
          italic = true,
          font = wezterm.font_with_fallback({
      ${mkFallback {
        weight = "ExtraLight";
        italic = true;
      }}
          }),
        },
      }
    '';

    # CJK language disambiguation rules (see cjkRules above).
    # High number so it runs after fontconfig's generic-family expansion.
    xdg.configFile."fontconfig/conf.d/99-cjk-lang.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
      ${cjkRules}
      </fontconfig>
    '';
  };
}
