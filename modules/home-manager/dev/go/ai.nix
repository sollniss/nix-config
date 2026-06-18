{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.mcp = {
    servers = {
      gopls-mcp = {
        command = lib.getExe pkgs.gopls;
        args = [ "mcp" ];
      };
    };
  };

  programs.claude-code = {
    lspServers.go = {
      command = lib.getExe pkgs.gopls;
      args = [ "serve" ];
      extensionToLanguage = {
        ".go" = "go";
      };
    };
  };
}
