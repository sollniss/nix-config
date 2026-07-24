{
  inputs,
  pkgs,
  config,
  ...
}:
let
  homeManagerModules = with inputs.self.modules.homeManager; [
    base
    theme

    desktops.cosmic

    services.syncthing

    programs.anki
    programs.firefox
    programs.keepassxc
    programs.thunderbird
    #programs.vscode
    programs.zed
    programs.wezterm
    programs.ssh

    # shell
    programs.shelltools
    programs.fish
    programs.helix

    programs.devtools
    dev.go
    dev.nix
  ];
in
{
  imports = homeManagerModules ++ [
    #../../../modules/home-manager/programs/something
  ];

  home.stateVersion = "25.05";

  prefs.secrets = {
    ankiSollniss = "${config.home.homeDirectory}/.anki-logins/sollniss.txt";
    ankiMzh = "${config.home.homeDirectory}/.anki-logins/mzh.txt";
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "zeditor";

    KOOHA_EXPERIMENTAL = "window-recording";
  };

  # Extra packages.
  home.packages = with pkgs; [
    inkscape
    kooha

    picard
    whipper

    #google-chrome

    # minecraft
    prismlauncher
  ];

  #programs.lutris = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    gamemode
  #    mangohud
  #    umu-launcher
  #    winetricks
  #  ];
  #};

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
        "${config.home.homeDirectory}/sync/keepass" = {
          id = "crijs-3d7pa";
          devices = [ "phone" ];
        };
        "${config.home.homeDirectory}/sync/photos" = {
          id = "0zloo-2xerr";
          devices = [ "phone" ];
        };
        "${config.home.homeDirectory}/sync/memos" = {
          id = "p7pmi-8794o";
          devices = [ "phone" ];
        };
      };
    };
  };

  # User specific config for base programs.
  programs = {
    anki = {
      profiles.sollniss.sync = {
        username = config.prefs.user.email;
        keyFile = config.prefs.secrets.ankiSollniss;
      };
      profiles.mzh.sync = {
        username = "m.kodama0410@gmail.com";
        keyFile = config.prefs.secrets.ankiMzh;
      };
      profiles.sollniss.default = true;
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

    git.settings = {
      user = {
        name = config.prefs.user.name;
        email = config.prefs.user.email;
        signingkey = "${config.home.homeDirectory}/.ssh/github.pub";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;
      # Force SSH auth over HTTPS.
      #url."git@github.com:".insteadOf = "https://github.com/";
    };

    jujutsu.settings = {
      user = {
        name = config.prefs.user.name;
        email = config.prefs.user.email;
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "${config.home.homeDirectory}/.ssh/github.pub";
      };
    };

    keepassxc.settings.General.LastOpenedDatabases = "${config.home.homeDirectory}/sync/keepass/Passwords.kdbx";

    ssh.settings = {
      "github.com" = {
        IdentityFile = "${config.home.homeDirectory}/.ssh/github.pub";
        IdentitiesOnly = true;
      };
      "raspberrypi ${config.prefs.network.hosts.raspberrypi.ip}" = {
        HostName = config.prefs.network.hosts.raspberrypi.ip;
        User = "root";
        IdentityFile = "${config.home.homeDirectory}/.ssh/pi.pub";
        IdentitiesOnly = true;
      };
    };
  };

  accounts.email.accounts = {
    "${config.prefs.user.email}" = {
      realName = config.prefs.user.name;
      address = config.prefs.user.email;
      userName = config.prefs.user.name;
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
        port = 465;
        authentication = "plain";
        tls = {
          enable = true;
        };
      };
    };
  };
}
