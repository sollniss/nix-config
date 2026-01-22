{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}: {
  programs.starship = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableFishIntegration = config.programs.fish.enable;
  };

  # ls alternative
  programs.eza = {
    enable = true;
    icons = "always";
  };

  # cat alternative
  programs.bat = {
    enable = true;
  };

  # find alternative
  programs.fd = {
    enable = true;
  };

  # cd alternative
  programs.zoxide = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableFishIntegration = config.programs.fish.enable;
    options = [
      "--cmd cd" # alias to cd
    ];
  };

  # tree alternative
  programs.broot = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableFishIntegration = config.programs.fish.enable;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableFishIntegration = config.programs.fish.enable;

    defaultCommand = "fd --type f";
  };

  programs.btop = {
    enable = true;
    # Enable GPU support.
    package = lib.mkIf osConfig.hardware.nvidia.modesetting.enable pkgs.btop-cuda;
  };

  home.shellAliases = {
    ".." = "cd ..";
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    tree = "broot";
  };
}
