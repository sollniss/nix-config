{
  inputs,
  pkgs,
  ...
}:
let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base
    theme

    desktops.gnome

    services.syncthing

    programs.firefox
    programs.thunderbird
    programs.vscode
    programs.keepassxc
  ];
in
{
  imports = homeManagerModules;

  home.username = "sollniss";
  home.homeDirectory = "/home/sollniss";
  home.stateVersion = "25.05";

  programs.eza = {
    enable = true;
    icons = "always";
  };

  programs.bat = {
    enable = true;
  };

  home.shellAliases = {
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    nixosbtw = "nix-shell -p fastfetch --run fastfetch";
  };

  # Extra packages.
  home.packages = with pkgs; [
    # development
    gopls # Go LSP
    nil # Nix LSP
  ];

  # Extra programs.
  programs.go = {
    enable = true;
    env.GOPATH = "code/go";
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
        "/home/sollniss/sync/keepass" = {
          id = "crijs-3d7pa";
          devices = [ "phone" ];
        };
      };
    };
  };

  # User specific config for base programs.
  programs = {

    keepassxc.settings.General.LastOpenedDatabases = "/home/sollniss/sync/keepass/Passwords.kdbx";

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

  # User specific config.
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "org.gnome.TextEditor.desktop"
        "signal.desktop"
        "thunderbird.desktop"
        "org.keepassxc.KeePassXC.desktop"
        "firefox.desktop"
        "org.wezfurlong.wezterm.desktop"
        "code.desktop"
      ];
    };
  };

  accounts.email.accounts = {
    "sollniss@web.de" = {
      realName = "sollniss";
      address = "sollniss@web.de";
      userName = "sollniss@web.de";
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
        tls.enable = true;
      };
    };
  };
}
