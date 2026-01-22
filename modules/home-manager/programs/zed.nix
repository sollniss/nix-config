{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    #extraPackages = with pkgs; [];
    #installRemoteServer = true;

    extensions = ["make"];
    #mutableUserSettings = false;
    userSettings = {
      terminal = {
        shell = {
          with_arguments = {
            program = "fish";
            args = ["-i"];
          };
        };
      };
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
}
