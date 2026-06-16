{ config, lib, ... }:
# WezTerm: use the builtin catppuccin color scheme (the catppuccin tab styling
# doesn't work on Cosmic) plus a custom tab bar. Colors are pulled from the live
# palette so they follow `catppuccin.flavor`/`catppuccin.accent`.
let
  inherit (config.catppuccin) accent;
  palette = config.theme.palette;
  c = name: palette.${name}.hex;
in
{
  catppuccin.wezterm.enable = false;
  programs.wezterm.extraConfig = ''
    config.color_scheme = "Catppuccin ${lib.toSentenceCase config.catppuccin.flavor}"
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
        { Background = { Color = "${c "surface0"}" } },
        { Foreground = { Color = "${c "text"}" } },
        { Text = ' + ' }
      }),
      new_tab_hover = wezterm.format({
        { Background = { Color = "none" } },
        { Foreground = { Color = "none" } },
        { Text = "  " },
        { Background = { Color = "${c "surface1"}" } },
        { Foreground = { Color = "${c "text"}" } },
        { Text = ' + ' }
      })
    }
    config.use_fancy_tab_bar = false
    wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
      local background = "${c "crust"}"
      local foreground = "${c "text"}"
      local edge_background = "none"
      if tab.is_active then
        background = "${c accent}"
        foreground = "${c "crust"}"
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
}
