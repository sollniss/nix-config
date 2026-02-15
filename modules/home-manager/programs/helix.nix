{
  lib,
  pkgs,
  ...
}:
let
  # Append one or more language servers to every configured language.
  #
  # - Only touches entries in `languages.language`.
  # - Preserves any existing per-language `language-servers`.
  # - Deduplicates while maintaining order (existing servers first).
  appendLanguageServersToAllLanguages =
    serversToAppend: languages:
    let
      ensureForLanguage =
        lang:
        let
          existing = lang.language-servers or [ ];
        in
        lang
        // {
          language-servers = lib.lists.unique (existing ++ serversToAppend);
        };
    in
    languages
    // {
      language = map ensureForLanguage (languages.language or [ ]);
    };
in
{
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      # Common stuff
      bash-language-server
      helix-gpt
    ];

    languages = appendLanguageServersToAllLanguages [ "gpt" ] {
      language-server.biome = {
        command = "biome";
        args = [ "lsp-proxy" ];
      };

      language-server.gpt = {
        command = "helix-gpt";
        args = [
          "--handler"
          "copilot"
        ];
      };

      #language = [];
    };
  };

  programs.git.settings.core.editor = "hx";
  programs.jujutsu.settings.ui.editor = "hx";
}
