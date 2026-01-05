{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    extraPackages = with pkgs; [
      # Go
      gopls
      gotools
      golangci-lint
      gofumpt
      delve
      gcc # required by golangci-lint

      # Nix
      nixd
      alejandra
    ];
    #installRemoteServer = true;

    extensions = ["nix" "make" "golangci-lint" "gosum"];
    #mutableUserSettings = false;
    userSettings = {
      format_on_save = "on";
      ui_font_family = "Noto Sans";
      buffer_font_family = "JetBrains Mono";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      lsp = {
        gopls = {
          gofumpt = true;
          initialization_options = {
            gofumpt = true;
          };
        };
        golangci-lint = {
          initialization_options = {
            command = [
              "golangci-lint"
              "run"
              "--output.json.path=stdout"
              "--issues-exit-code=1"
              "--show-stats=false"
            ];
          };
        };
      };
      languages = {
        Nix = {
          language_servers = ["nixd"];
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              command = "alejandra";
              #arguments = ["--quiet" "--"];
            };
          };
        };
        Go = {
          language_servers = ["gopls" "golangci-lint"];
          tab_size = 4;
          format_on_save = "on";
          formatter = {
            external = {
              command = "gofumpt";
            };
          };
        };
      };
    };
  };
}
