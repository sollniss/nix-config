{ ... }:
{
  programs.zed-editor = {
    enable = true;
    #extraPackages = with pkgs; [];
    #installRemoteServer = true;

    extensions = [
      "make"
      "toml"
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
