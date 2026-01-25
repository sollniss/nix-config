{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    cursors.enable = config.prefs.profile.graphical.enable;

    # Below apps are broken. Use custom setting.
    firefox.enable = false;
    wezterm.enable = false;

    # following programs can use terminal colors,
    # no need to style them separately
    eza.enable = false;
    starship.enable = false;
  };

  # Firefox
  programs.firefox.policies.ExtensionSettings = {
    "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-mauve-git/latest.xpi";
      installation_mode = "force_installed";
      updates_disabled = "false";
      private_browsing = "true";
    };
  };
  #}

  # WezTerm
  programs.wezterm.extraConfig = ''
    config.color_scheme = "Catppuccin Mocha"
  '';

  # KeePassXC
  programs.keepassxc.settings.GUI.ApplicationTheme = "dark";
}
