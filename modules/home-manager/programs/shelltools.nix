{
  osConfig,
  config,
  pkgs,
  lib,
  ...
}:
{
  home.shell.enableShellIntegration = false;
  home.shell.enableBashIntegration = config.programs.bash.enable;
  home.shell.enableFishIntegration = config.programs.fish.enable;

  programs.starship = {
    enable = true;
  };

  # ls alternative
  programs.eza = {
    enable = true;
    icons = "always";
    extraOptions = [
      "--group-directories-first"
      "--no-permissions"
      "--octal-permissions"
    ];
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
    options = [
      "--cmd cd" # alias to cd
    ];
  };

  # tree alternative
  programs.broot = {
    enable = true;

    settings = {
      icon_theme = "nerdfont";
    };
  };

  programs.fzf = {
    enable = true;

    defaultCommand = "${lib.getExe config.programs.fd.package} --type f";
  };

  programs.btop = {
    enable = true;
    # Enable GPU support.
    package = lib.mkIf (
      osConfig != null && lib.attrByPath [ "hardware" "nvidia" "modesetting" "enable" ] false osConfig
    ) pkgs.btop-cuda;
  };

  home.shellAliases = {
    ".." = "cd ..";
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    tree = "br -c :pt"; # https://dystroy.org/broot/tricks/#replace-tree
  };
}
