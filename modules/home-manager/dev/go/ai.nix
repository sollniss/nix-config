{
  config,
  pkgs,
  ...
}:
{
  programs.claude-code = {
    settings = {
      enabledPlugins = {
        "gopls-lsp@claude-plugins-official" = true;
      };
    };
  };
}
