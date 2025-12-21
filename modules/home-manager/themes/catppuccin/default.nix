{
  config,
  lib,
  ...
}: {
  config = lib.mkMerge [
    {
      catppuccin = {
        enable = true;
        cursors.enable = true;

        # Below apps are broken. Use custom setting.
        fcitx5.enable = false;
        firefox.enable = false;
        wezterm.enable = false;
      };
    }

    # fcitx5
    (lib.mkIf (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5") {
      xdg.dataFile = {
        "fcitx5/themes/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}" = {
          source = "${config.catppuccin.sources.fcitx5}/share/fcitx5/themes/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}";
          recursive = true;
        };
      };
      i18n.inputMethod.fcitx5 = {
        settings.addons.classicui.globalSection = {
          Theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}";
        };
      };
    })

    # Firefox
    {
      programs.firefox.policies.ExtensionSettings = {
        "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-mauve-git/latest.xpi";
          installation_mode = "force_installed";
          updates_disabled = "false";
          private_browsing = "true";
        };
      };
    }

    # WezTerm
    {
      programs.wezterm.extraConfig = ''
        config.color_scheme = "Catppuccin Mocha"
      '';
    }

    # KeePassXC
    {
      programs.keepassxc.settings.GUI.ApplicationTheme = "dark";
    }
  ];
}
