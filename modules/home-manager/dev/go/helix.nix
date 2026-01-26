{
  config,
  pkgs,
  ...
}:
{
  programs.helix = {
    extraPackages =
      config.dev.go.neededPackages
      ++ (with pkgs; [
        golangci-lint-langserver
      ]);

    languages.language = [
      {
        name = "go";
        language-servers = [
          "gopls"
          "golangci-lint-lsp"
          "gpt"
        ];
        auto-format = true;
      }
    ];
  };
}
