{ pkgs, lib, ... }:
let
  keepassxc-proxy = pkgs.writeShellScript "keepassxc-proxy" ''
    if ! ${lib.getExe' pkgs.openssh "ssh-add"} -l &> /dev/null; then
      # Trigger KeePassXC's Secret Service unlock dialog via D-Bus.
      # This shows a modal prompt that auto-dismisses after unlock.
      ${lib.getExe' pkgs.libsecret "secret-tool"} search --unlock nonexistent dummy &> /dev/null &
      for i in $(seq 1 10); do
        ${lib.getExe' pkgs.openssh "ssh-add"} -l &> /dev/null && break
        sleep 1
      done
    fi
    exec ${lib.getExe' pkgs.libressl.nc "nc"} "$1" "$2"
  '';
in
{
  programs.keepassxc = {
    enable = true;
    autostart = true;
    # Options
    # https://github.com/keepassxreboot/keepassxc/blob/develop/src/core/Config.cpp
    settings = {
      General = {
        ConfigVersion = "2";
        BackupBeforeSave = true;
        UpdateCheckMessageShown = true;
        OpenPreviousDatabasesOnStartup = true;
      };
      Security = {
        LockDatabaseIdleSeconds = 3600;
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

  # Browser integration

  programs.keepassxc.settings.Browser = {
    Enabled = true;
    SearchInAllDatabases = true;
    BestMatchOnly = true;
    # When using enable = true, KeePassXC’ builtin native messaging manifest for
    # communication with its browser extension is automatically installed.
    # This conflicts with KeePassXC’ builtin installation mechanism.
    # To prevent error messages,
    # either set programs.keepassxc.settings.Browser.UpdateBinaryPath to false,
    # or untick the checkbox
    # Application Settings/Browser Integration/Advanced/Update native messaging manifest files at startup
    # in the GUI.
    UpdateBinaryPath = false;
  };

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

  # SSH

  services.ssh-agent.enable = true;
  programs.keepassxc.settings.SSHAgent.Enabled = true;

  # When a KeePassXC entry has "Require user confirmation when this key is used" enabled,
  # ssh-agent needs an askpass program to show a yes/no confirmation dialog.
  # These must be set on the agent's systemd service, not just the shell session,
  # because the agent process itself invokes the askpass program.
  home.sessionVariables = {
    SSH_ASKPASS = lib.getExe pkgs.lxqt.lxqt-openssh-askpass;
    SSH_ASKPASS_REQUIRE = "prefer";
  };
  systemd.user.services.ssh-agent.Service.Environment = [
    "SSH_ASKPASS=${lib.getExe pkgs.lxqt.lxqt-openssh-askpass}"
    "SSH_ASKPASS_REQUIRE=prefer"
    "DISPLAY=:0"
  ];

  # Prompt to unlock KeePassXC when SSH needs a key that isn't in the agent.
  # The script launches KeePassXC (which prompts for the master password),
  # waits for the key to appear in the agent, then connects via netcat.
  programs.ssh.settings."*".ProxyCommand = "${keepassxc-proxy} %h %p";
}
