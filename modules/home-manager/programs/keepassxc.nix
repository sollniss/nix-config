{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  # Wrapper around SSH_ASKPASS that caches approval for a short window.
  # Avoids repeated confirmation dialogs for back-to-back operations
  # (e.g., sign + push).
  ssh-askpass-cached = pkgs.writeShellScript "ssh-askpass-cached" ''
    CACHE_FILE="/tmp/.ssh-askpass-cache-$(id -u)"
    CACHE_SECONDS=60

    if [ -f "$CACHE_FILE" ]; then
      last=$(cat "$CACHE_FILE")
      now=$(date +%s)
      if [ $((now - last)) -lt $CACHE_SECONDS ]; then
        exit 0
      fi
    fi

    ${lib.getExe pkgs.lxqt.lxqt-openssh-askpass} "$@"
    status=$?

    if [ $status -eq 0 ]; then
      date +%s > "$CACHE_FILE"
    fi

    exit $status
  '';
  cosmic-secret-unlock =
    inputs.cosmic-secret-unlock.packages.${pkgs.stdenv.hostPlatform.system}.default;

  keepassxc-unlock = pkgs.writeShellScript "keepassxc-unlock" ''
    # Trigger KeePassXC's Secret Service unlock via D-Bus.
    # If the unlock dialog blocks, force-focus the KeePassXC window
    # using COSMIC's toplevel management protocol.
    ${lib.getExe cosmic-secret-unlock} org.keepassxc.KeePassXC
  '';

  keepassxc-proxy = pkgs.writeShellScript "keepassxc-proxy" ''
    if ! ${lib.getExe' pkgs.openssh "ssh-add"} -l &> /dev/null; then
      ${keepassxc-unlock}
    fi
    exec ${lib.getExe' pkgs.libressl.nc "nc"} "$1" "$2"
  '';

  # Wrapper around ssh-keygen that triggers KeePassXC unlock before signing
  # if the signing key isn't in the agent yet.
  ssh-keygen-sign = pkgs.writeShellScript "ssh-keygen-sign" ''
    if ! ${lib.getExe' pkgs.openssh "ssh-add"} -l &> /dev/null; then
      ${keepassxc-unlock}
    fi
    exec ${lib.getExe' pkgs.openssh "ssh-keygen"} "$@"
  '';
in
{
  config = {
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
        Browser = {
          Enabled = true;
          SearchInAllDatabases = true;
          BestMatchOnly = true;
          # When using enable = true, KeePassXC' builtin native messaging manifest for
          # communication with its browser extension is automatically installed.
          # This conflicts with KeePassXC' builtin installation mechanism.
          # To prevent error messages,
          # either set programs.keepassxc.settings.Browser.UpdateBinaryPath to false,
          # or untick the checkbox
          # Application Settings/Browser Integration/Advanced/Update native messaging manifest files at startup
          # in the GUI.
          UpdateBinaryPath = false;
        };
        SSHAgent.Enabled = true;
        FdoSecrets.Enabled = true;
        Security.IconDownloadFallback = true;
      };
    };
    xdg.autostart.enable = config.programs.keepassxc.autostart;

    # Disable gnome keyring service
    #services.gnome-keyring.enable = lib.mkForce false; # Does not work.

    # Browser integration

    programs.firefox = lib.mkIf config.programs.keepassxc.settings.Browser.Enabled {
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

    services.ssh-agent.enable = config.programs.keepassxc.settings.SSHAgent.Enabled;

    # When a KeePassXC entry has "Require user confirmation when this key is used" enabled,
    # ssh-agent needs an askpass program to show a yes/no confirmation dialog.
    # These must be set on the agent's systemd service, not just the shell session,
    # because the agent process itself invokes the askpass program.
    home.sessionVariables = lib.mkIf config.programs.keepassxc.settings.SSHAgent.Enabled {
      SSH_ASKPASS = toString ssh-askpass-cached;
      SSH_ASKPASS_REQUIRE = "prefer";
    };
    # askpass needs display/wayland specific environment variables
    # so we make it depend of the graphical session.
    # This makes it unusable in terminal sessions.
    systemd.user.services.ssh-agent = lib.mkIf config.programs.keepassxc.settings.SSHAgent.Enabled {
      Unit = {
        After = [ "graphical-session.target" ];
        Requires = [ "graphical-session.target" ];
      };
      Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
      Service.Environment = [
        "SSH_ASKPASS=${ssh-askpass-cached}"
        "SSH_ASKPASS_REQUIRE=prefer"
      ];
    };

    # Prompt to unlock KeePassXC when SSH needs a key that isn't in the agent.
    # The script launches KeePassXC (which prompts for the master password),
    # waits for the key to appear in the agent, then connects via netcat.
    programs.ssh.settings."*".ProxyCommand = lib.mkIf (
      config.programs.keepassxc.settings.SSHAgent.Enabled
      && config.programs.keepassxc.settings.FdoSecrets.Enabled
    ) "${keepassxc-proxy} %h %p";

    # SSH commit signing: trigger KeePassXC unlock if key isn't in the agent.
    programs.git.settings.gpg.ssh.program = lib.mkIf (
      config.programs.keepassxc.settings.SSHAgent.Enabled
      && config.programs.keepassxc.settings.FdoSecrets.Enabled
      && (config.programs.git.settings.gpg.format or "") == "ssh"
    ) (toString ssh-keygen-sign);
    programs.jujutsu.settings.signing.backends.ssh.program = lib.mkIf (
      config.programs.keepassxc.settings.SSHAgent.Enabled
      && config.programs.keepassxc.settings.FdoSecrets.Enabled
      && config.programs.jujutsu.enable
      && (config.programs.jujutsu.settings.signing.backend or "") == "ssh"
    ) (toString ssh-keygen-sign);
  };
}
