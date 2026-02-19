{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
  ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";

    cursors.enable = config.prefs.profile.graphical.enable;

    thunderbird.profile = "default";

    # The following programs can use terminal colors,
    # no need to style them separately.
    eza.enable = false;
    starship.enable = false;
  };

  # Firefox: use theme instead of "Firefox Color" extension.
  catppuccin.firefox.enable = false;
  programs.firefox.policies.ExtensionSettings = {
    "{76aabc99-c1a8-4c1e-832b-d4f2941d5a7a}" = {
      install_url = "https://addons.mozilla.org/firefox/downloads/latest/catppuccin-mocha-mauve-git/latest.xpi";
      installation_mode = "force_installed";
      updates_disabled = "false";
      private_browsing = "true";
    };
  };
  #}

  # WezTerm: use builtin theme.
  catppuccin.wezterm.enable = false;
  programs.wezterm.extraConfig = ''
    config.color_scheme = "Catppuccin Mocha"
  '';

  # GTK: use inofficial catppuccin theme.
  # https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme
  gtk = {
    enable = config.prefs.profile.graphical.enable;
    theme = {
      package = pkgs.magnetic-catppuccin-gtk.override {
        accent = [ config.catppuccin.accent ];
        #tweaks = [ "black" ];
        shade = "dark"; # mocha
      };
      name = "Catppuccin-GTK-Mauve-Dark";
    };
  };

  # qt (not sure if this actually works)
  catppuccin.kvantum.apply = config.prefs.profile.graphical.enable;
  qt = {
    enable = config.prefs.profile.graphical.enable;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # KeePassXC: qt5, but doesn't apply theme. Force dark mode at least.
  programs.keepassxc.settings.GUI.ApplicationTheme = "dark";
}
