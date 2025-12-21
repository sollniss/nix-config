{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        golang.go
      ];
      userSettings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.serverSettings"."nixd"."formatting"."command" = ["${pkgs.alejandra}/bin/alejandra"];
        "[nix]"."editor.tabSize" = 2;

        "explorer.confirmDelete" = false;
        "editor.selectionClipboard" = false;
        "terminal.integrated.gpuAcceleration" = "auto";
      };
    };
  };
}
