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
    profiles."default".isDefault = true;
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
}
