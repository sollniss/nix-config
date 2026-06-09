{
  lib,
  inputs,
  pkgs,
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    #package = inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default;
    #extraPackages = with pkgs; [];
    #installRemoteServer = true;

    extensions = [
      "sql"
      "make"
      "toml"
      "log"
    ];
    #mutableUserSettings = false;
    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      format_on_save = "on";
      agent_servers = {
        "claude-acp" = {
          type = "registry";
          env = {
            CLAUDE_CODE_EXECUTABLE = lib.getExe pkgs.claude-code;
          };
        };
      };
      lsp = {
        "vscode-html-language-server" = {
          settings = {
            html = {
              format = {
                indentInnerHtml = true;
                contentUnformatted = "svg,script";
                extraLiners = "div,p";
              };
            };
          };
        };
      };
      languages = {
        "HTML" = {
          formatter = "language_server";
        };
      };
    };
  };

  home.shellAliases = {
    zed = "zeditor";
  };
}
