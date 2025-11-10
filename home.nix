{ config, pkgs, ... }:

{

  home.username = "sollniss";
  home.homeDirectory = "/home/sollniss";
  home.stateVersion = "25.05";

  # this makes only firefox dark
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # IME
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        fcitx5-mozc # Japanese input method
      ];

      settings.inputMethod = {
        GroupOrder = {
          "0" = "Default";
        };
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = "";
        };
      };
    };
  };

  services.syncthing = {
    enable = true;
    settings = {
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
      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = true;
        # Whether the user has accepted to submit anonymous usage data.
        # The default, 0, mean the user has not made a choice, and Syncthing will ask at some point in the future.
        # "-1" means no, a number above zero means that that version of usage reporting has been accepted.
        urAccepted = -1;
      };
    };
  };

  home.packages = with pkgs; [
    gopls # Go LSP
    nil # Nix LSP

    signal-desktop
  ];

  imports = [
    ./progs/firefox.nix
  ];

  programs.bash = {
    enable = true;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };

  programs.go = {
    enable = true;
    env.GOPATH = "code/go";
  };

  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
      userSettings = {
        "editor.selectionClipboard" = false;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "[nix]"."editor.tabSize" = 2;
      };
    };
  };

  programs.keepassxc = {
    enable = true;
    autostart = true;
    # Options
    # https://github.com/keepassxreboot/keepassxc/blob/44daca921a0e860845368c0d1697cea86ed79be0/src/core/Config.cpp#L52
    settings = {
      General = {
        ConfigVersion = "2";
        BackupBeforeSave = true;
        UpdateCheckMessageShown = true;
        LastOpenedDatabases = "/home/sollniss/sync/keepass/Passwords.kdbx";
        OpenPreviousDatabasesOnStartup = true;
      };
      Browser = {
        Enabled = true;
        SearchInAllDatabases = true;
        BestMatchOnly = true;
        # When using enable = true, KeePassXC’ builtin native messaging manifest for communication with its browser extension is automatically installed.
        # This conflicts with KeePassXC’ builtin installation mechanism.
        # To prevent error messages, either set programs.keepassxc.settings.Browser.UpdateBinaryPath to false, or untick the checkbox
        # Application Settings/Browser Integration/Advanced/Update native messaging manifest files at startup
        # in the GUI.
        UpdateBinaryPath = false;
      };
      GUI = {
        AdvancedSettings = true;
        CompactMode = true;
        MinimizeOnStartup = true;
        MinimizeOnClose = true;
        ShowExpiredEntriesOnDatabaseUnlockOffsetDays = "30";
        ShowTrayIcon = true;
      };
      PasswordGenerator = {
        AdvancedMode = true;
        Length = "32";
        Punctuation=true;
        Dashes = true;
        Math = true;
        Braces = true;
        Quotes = true;
      };
      FdoSecrets.Enabled = true;
      Security.IconDownloadFallback = true;
    };
  };
  xdg.autostart.enable = true;

  #programs.lutris = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    gamemode
  #    mangohud
  #    umu-launcher
  #    winetricks
  #  ];
  #};
}
