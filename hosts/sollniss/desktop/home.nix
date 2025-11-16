{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
let
  homeManagerModules = with inputs.self.homeManagerModules; [
    base
    theme

    services.syncthing

    programs.firefox
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

  programs = {

    keepassxc.settings.General.LastOpenedDatabases = "/home/sollniss/sync/keepass/Passwords.kdbx";

    git.settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };

  };

  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;

      settings = {
        "mailnews.default_sort_type" = 18;
        "mailnews.default_sort_order" = 2;
        "mailnews.default_news_sort_order" = 2;
        "mailnews.default_news_sort_type" = 18;
      };
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

  #programs.anki = {
  #  enable = true;
  #  #sync.username = "sollniss";
  #};

  programs.lutris = {
    enable = true;
    extraPackages = with pkgs; [
      gamemode
      mangohud
      umu-launcher
      winetricks
    ];
  };
}
