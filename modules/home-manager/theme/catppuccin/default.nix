{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
let
  # Live catppuccin palette for the selected flavor.
  palette =
    (lib.importJSON "${config.catppuccin.sources.palette}/palette.json")
    .${config.catppuccin.flavor}.colors;
in
{
  imports = [
    inputs.catppuccin.homeModules.catppuccin
    ./filetools.nix
    ./wezterm.nix
  ];

  # Resolved catppuccin palette for the active flavor (color name -> { hex; rgb;
  # ... }), so sibling modules can theme from one source instead of each reading
  # palette.json. Follows `catppuccin.flavor`. Read-only: change colors via
  # `catppuccin.flavor`/`catppuccin.accent`, not by setting this.
  options.theme.palette = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    description = "Resolved catppuccin palette for the active flavor.";
  };

  config = {
    theme.palette = palette;

    catppuccin = {
      enable = true;
      autoEnable = true;
      flavor = "mocha";
      accent = "mauve";

      cursors.enable = config.prefs.profile.graphical.enable;

      #wezterm.apply = true;
      thunderbird.profile = "default";

      # The following programs can use terminal colors,
      # no need to style them separately.
      #eza.enable = false;
      #yazi.enable = true;
      #starship.enable = false;
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
      gtk4.theme = null;
    };

    # qt (not sure if this actually works)
    catppuccin.kvantum.apply = config.prefs.profile.graphical.enable;
    qt = {
      enable = config.prefs.profile.graphical.enable;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    # KeePassXC: force system theme.
    programs.keepassxc.settings.GUI.ApplicationTheme = "classic";
  };
}
