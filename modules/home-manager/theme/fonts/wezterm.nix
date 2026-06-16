{ config, lib, ... }:
let
  inherit (config.theme.fonts) monospace emoji;

  # WezTerm only consults the system fallback after its own bundled fonts, so
  # list our system fonts explicitly to enforce them.
  weztermFonts = lib.concatMapStringsSep ", " (f: ''"${f}"'') (monospace ++ [ (lib.head emoji) ]);

  # WezTerm synthesizes any requested bold/italic a font lacks.
  # To get native-only rendering we request each variant only from fonts that
  # actually ship it.
  # Everything else resolves to its native face.
  # Native variants in our stack:
  #   - JetBrains Mono: bold, italic, bold-Italic.
  #   - Noto (mono + CJK): bold, no italic.
  #   - Symbols Nerd Font Mono + emoji: no bold, no italic.
  # The symbol font is the last monospace entry by convention.
  italicFonts = [ (lib.head monospace) ]; # has italics
  textFonts = lib.init monospace; # has weights (incl. bold)
  bareFonts = [
    # no bold, no italic
    (lib.last monospace)
    (lib.head emoji)
  ];

  # Render the Lua font_with_fallback entries for a font_rule.
  # `weight` (or null) is applied to the text fonts.
  # `italic` adds style="Italic" only to fonts that have a native italic.
  # Fonts left with no attributes are emitted as bare names
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
in
{
  config = lib.mkIf config.prefs.profile.graphical.enable {
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
  };
}
