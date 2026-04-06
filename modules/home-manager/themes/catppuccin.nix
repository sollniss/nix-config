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

    #wezterm.apply = true;
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

  # WezTerm: use builtin theme,
  # since the catppuccin tab styling doesn't work on Cosmic.
  catppuccin.wezterm.enable = false;
  programs.wezterm.extraConfig = ''
    config.color_scheme = "Catppuccin Mocha"
    function tab_title(tab_info)
      local title = tab_info.tab_title
      if title and #title > 0 then
        return title
      end
      return tab_info.active_pane.title
    end
    config.colors = {
      tab_bar = {
        background = "none",
      },
    }
    config.tab_bar_style = {
      new_tab = wezterm.format({
        { Background = { Color = "none" } },
        { Foreground = { Color = "none" } },
        { Text = "  " },
        { Background = { Color = "#313244" } },
        { Foreground = { Color = "#cdd6f4" } },
        { Text = ' + ' }
      }),
      new_tab_hover = wezterm.format({
        { Background = { Color = "none" } },
        { Foreground = { Color = "none" } },
        { Text = "  " },
        { Background = { Color = "#45475a" } },
        { Foreground = { Color = "#cdd6f4" } },
        { Text = ' + ' }
      })
    }
    config.use_fancy_tab_bar = false
    wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
      local background = "#11111b"
      local foreground = "#cdd6f4"
      local edge_background = "none"
      if tab.is_active then
        background = "#cba6f7"
        foreground = "#11111b"
      end
      local edge_foreground = background
      local title = tab_title(tab)
      title = " " .. wezterm.truncate_left(title, max_width - 5) .. " "
      return {
        { Background = { Color = "none" } },
        { Foreground = { Color = "none" } },
        { Text = " " },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = wezterm.nerdfonts.ple_lower_right_triangle },
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
        { Background = { Color = edge_background } },
        { Foreground = { Color = edge_foreground } },
        { Text = wezterm.nerdfonts.ple_upper_left_triangle },
      }
    end)
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
}
