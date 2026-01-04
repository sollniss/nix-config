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

      # Nix
      nixd
      alejandra
    ];
    #installRemoteServer = true;

    extensions = ["nix" "make"];
    #mutableUserSettings = false;
    userSettings = {
      format_on_save = "on";
      ui_font_family = "Noto Sans";
      buffer_font_family = "JetBrains Mono";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      #lsp = {
      #  gopls = {
      #    binary = {
      #      path_lookup = true;
      #    };
      #  };
      #  nixd = {
      #    binary = {
      #      path_lookup = true;
      #    };
      #    #initialization_options = {
      #    #  formatting = {
      #    #    command = "alejandra";
      #    #    arguments = ["--quiet" "--"];
      #    #  };
      #    #};
      #  };
      #};
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
          language_servers = ["gopls"];
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
