{ inputs, pkgs, ... }:
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
      ui_font_family = "Noto Sans";
      buffer_font_family = "JetBrains Mono NL";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      format_on_save = "on";
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
