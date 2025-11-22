{
  ...
}:
{
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
        Punctuation = true;
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

  # Disable gnome keyring service
  #services.gnome-keyring.enable = lib.mkForce false; # Does not work.

  programs.firefox = {
    policies = {
      ExtensionSettings = {
        # KeePassXC-Browser
        "keepassxc-browser@keepassxc.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
          installation_mode = "force_installed";
          updates_disabled = "false";
          private_browsing = "true";
        };
      };

      "3rdparty".Extensions = {
        # https://github.com/keepassxreboot/keepassxc-browser/blob/develop/keepassxc-browser/background/page.js
        "keepassxc-browser@keepassxc.org".settings = {
          "passkeys" = true;
        };
      };
    };
  };
}
