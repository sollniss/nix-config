{
  inputs,
  pkgs,
  config,
  ...
}:
let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base
    themes

    desktops.cosmic

    services.syncthing

    programs.anki
    programs.firefox
    programs.keepassxc
    programs.thunderbird
    #programs.vscode
    programs.zed
    programs.wezterm

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

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "zeditor";
  };

  # Extra packages.
  home.packages = with pkgs; [
    inkscape
    gg-jj

    #google-chrome

    # minecraft
    #prismlauncher
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
        username = "sollniss" + "@" + "web.de";
        keyFile = "${config.home.homeDirectory}/.anki-logins/sollniss.txt";
      };
      profiles.mzh.sync = {
        username = "m." + "kodama0410" + "@" + "gmail" + ".com";
        keyFile = "${config.home.homeDirectory}/.anki-logins/mzh.txt";
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

    git.settings.user = {
      name = "sollniss";
      email = "sollniss" + "@" + "web.de";
    };

    jujutsu.settings.user = {
      name = "sollniss";
      email = "sollniss" + "@" + "web.de";
    };

    keepassxc.settings.General.LastOpenedDatabases = "${config.home.homeDirectory}/sync/keepass/Passwords.kdbx";
  };

  accounts.email.accounts = {
    "sollniss@web.de" = {
      realName = "sollniss";
      address = "sollniss" + "@" + "web.de";
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
        port = 465;
        authentication = "digest_md5";
        tls = {
          enable = true;
        };
      };
    };
  };
}
