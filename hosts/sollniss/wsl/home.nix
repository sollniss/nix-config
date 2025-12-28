{
  inputs,
  vars,
  pkgs,
  ...
}: let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base.shell
    themes.catppuccin

    programs.shelltools
    programs.fish
    programs.helix
  ];
in {
  imports = homeManagerModules;

  programs.home-manager.enable = true;
  home.username = vars.username;
  home.homeDirectory = "/home/${vars.username}";
  home.stateVersion = "25.05";

  programs.bash = {
    enable = true;
  };

  # Extra packages.
  home.packages = with pkgs; [
    # development
    gopls # Go LSP
    gofumpt
    gcc
    delve
    #nil # Nix LSP
    nixd
    alejandra
  ];

  programs.zed-editor = {
    enable = true;
    installRemoteServer = true;

    extensions = [ "nix" "make" ];
    #mutableUserSettings = false;
    userSettings = {
      hour_format = "hour24";
      format_on_save = "on";
      ui_font_family = "Noto Sans";
      buffer_font_family = "JetBrains Mono";
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      lsp = {
        gopls = {
          binary = {
            path_lookup = true;
          };
        };
        nixd = {
          binary = {
            path_lookup = true;
          };
          #initialization_options = {
          #  formatting = {
          #    command = "alejandra";
          #    arguments = ["--quiet" "--"];
          #  };
          #};
        };
      };
      languages = {
        Nix = {
          language_servers = [ "nixd" ];
          tab_size = 2;
          formatter = {
            external = {
              command = "alejandra";
              arguments = ["--quiet" "--"];
            };
          };
        };
        Go = {
          language_servers = [ "gopls" ];
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

  # Extra programs.
  programs.go = {
    enable = true;
    env.GOPATH = "/home/${vars.username}/code/go";
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
