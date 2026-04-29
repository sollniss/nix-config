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
      buffer_font_family = "JetBrains Mono";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      format_on_save = "on";
      #lsp = {};
      #languages = {};
    };
  };

  home.shellAliases = {
    zed = "zeditor";
  };
}
