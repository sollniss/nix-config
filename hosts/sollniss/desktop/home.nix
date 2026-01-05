{
  inputs,
  vars,
  lib,
  pkgs,
  config,
  ...
}: let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base.gui
    base.shell
    themes.gui
    themes.catppuccin

    desktops.cosmic

    services.syncthing

    programs.firefox
    programs.thunderbird
    programs.vscode
    programs.zed
    programs.keepassxc

    # shell
    programs.shelltools
    programs.fish
    programs.helix
  ];
in {
  imports = homeManagerModules;

  home.username = vars.username;
  home.homeDirectory = "/home/${vars.username}";
  home.stateVersion = "25.05";

  # Extra packages.
  home.packages = with pkgs; [
    # development
    #gopls # Go LSP
    #gcc
    #nil # Nix LSP
    #nixd

    # minecraft
    prismlauncher
  ];

  # Extra programs.
  programs.go = {
    enable = true;
    env = {
      GOPATH = "${config.home.homeDirectory}/go";
      GOBIN = "${config.home.homeDirectory}/go/bin";
    };
  };

  programs.wezterm = {
    enable = true;
    extraConfig = lib.mkMerge [
      (lib.mkBefore ''
        local config = wezterm.config_builder()
      '')
      (lib.mkAfter ''
        -- This is where you actually apply your config choices.

        -- For example, changing the initial geometry for new windows:
        config.initial_cols = 120
        config.initial_rows = 28

        -- or, changing the font size and color scheme.
        config.font_size = 12

        config.default_prog = { 'fish', '-i' }

        -- Finally, return the configuration to wezterm:
        return config
      '')
    ];
  };

  programs.lutris = {
    enable = true;
    extraPackages = with pkgs; [
      gamemode
      mangohud
      umu-launcher
      winetricks
    ];
  };

  # User specific config for base services.
  services = {
    syncthing.settings = {
      devices = {
        phone = {
          addresses = [
            "dynamic"
          ];
          id = "WMPYVNZ-MMUZJ2Y-NZ7MT2A-ERJIHMU-3OO3TCM-WJPZYVO-PT2BGED-5WMIRQZ";
        };
      };
      folders = {
        "/home/${vars.username}/sync/keepass" = {
          id = "crijs-3d7pa";
          devices = ["phone"];
        };
        "/home/${vars.username}/sync/photos" = {
          id = "0zloo-2xerr";
          devices = ["phone"];
        };
        "/home/${vars.username}/sync/memos" = {
          id = "p7pmi-8794o";
          devices = ["phone"];
        };
      };
    };
  };

  # User specific config for base programs.
  programs = {
    keepassxc.settings.General.LastOpenedDatabases = "/home/${vars.username}/sync/keepass/Passwords.kdbx";

    git.settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };

    firefox.policies.ExtensionSettings = {
      # 10ten
      "{59812185-ea92-4cca-8ab7-cfcacee81281}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/10ten-ja-reader/latest.xpi";
        installation_mode = "force_installed";
        updates_disabled = "false";
        private_browsing = "true";
      };
    };
  };

  accounts.email.accounts = {
    "sollniss@web.de" = {
      realName = "sollniss";
      address = "sollniss@web.de";
      userName = "sollniss";
      primary = true;
      thunderbird = {
        enable = true;
      };

      imap = {
        host = "imap.web.de";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.web.de";
        port = 587;
        tls = {
          enable = true;
          useStartTls = true;
        };
      };
    };
  };
}
