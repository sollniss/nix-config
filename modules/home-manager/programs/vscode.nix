{
  pkgs,
  ...
}:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "[nix]"."editor.tabSize" = 2;

        "explorer.confirmDelete" = false;
        "editor.selectionClipboard" = false;
      };
    };
  };
}
