{
  osConfig,
  pkgs,
  ...
}:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
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
    enableBashIntegration = true;
    enableFishIntegration = true;
    options = [
      "--cmd cd" # alias to cd
    ];
  };

  # tree alternative
  programs.broot = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    defaultCommand = "fd --type f";
  };

  programs.btop = {
    enable = true;
    # Enable GPU support.
    package = (if osConfig.hardware.nvidia.modesetting.enable then pkgs.btop-cuda else pkgs.btop );
  };

  home.shellAliases = {
    ".." = "cd ..";
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    tree = "broot";
  };
}
