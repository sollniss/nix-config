{lib, ...}: {
  programs.wezterm = {
    enable = true;
    extraConfig = lib.mkMerge [
      (lib.mkBefore ''
        local config = wezterm.config_builder()
      '')
      (lib.mkAfter ''
        config.initial_cols = 120
        config.initial_rows = 28
        config.font_size = 12
        config.front_end = "WebGpu"
        return config
      '')
    ];
  };
}
