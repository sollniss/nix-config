{ lib, ... }:
{
  programs.wezterm = {
    enable = true;
    extraConfig = lib.mkMerge [
      # local config = wezterm.config_builder()
      # validates every assigment on every startup, which we don't need.
      (lib.mkBefore ''
        local config = {}
      '')
      (lib.mkAfter ''
        config.initial_cols = 120
        config.initial_rows = 28
        config.font_size = 12
        config.front_end = "WebGpu"
        config.window_close_confirmation = 'NeverPrompt'
        config.use_ime = true
        config.enable_kitty_keyboard = true
        return config
      '')
    ];
  };
}
