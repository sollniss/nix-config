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
    # Replaced below with an init script generated at build time.
    enableFishIntegration = false;
  };
  # Home Manager's integration runs `starship init fish | source`, which starts
  # starship twice per shell (a loader, then the full script; ~10 ms). Generate
  # the full script once instead. Same TERM guard as Home Manager's.
  programs.fish.interactiveShellInit =
    lib.mkIf config.programs.fish.enable
      (
        let
          init = pkgs.runCommand "starship-init.fish" { } ''
            ${lib.getExe config.programs.starship.package} init fish --print-full-init > $out
          '';
        in
        ''
          if test "$TERM" != dumb -a "$TERM" != linux
            source ${init}
          end
        ''
      );

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

  programs.ripgrep-all = {
    enable = true;
  };

  programs.yazi = {
    enable = true;
    shellWrapperName = "y";

    keymap.mgr.prepend_keymap = [
      {
        on = "o";
        run = "shell '$EDITOR %s' --block";
        desc = "Open with $EDITOR";
      }
      {
        on = "e";
        run = "shell '$VISUAL %s' --orphan";
        desc = "Open with $VISUAL";
      }
      {
        on = "<Enter>";
        # xdg-open takes ~800ms on COSMIC, gio ~60ms.
        run = "shell '${lib.getExe' pkgs.glib "gio"} open %s' --orphan";
        desc = "Open with default application";
      }
      {
        on = "S";
        run = "search --via=rga";
        desc = "Search files by content via ripgrep-all";
      }
    ];
  };

  programs.less = {
    enable = true;
    config = ''
      #command
      h left-scroll
      l right-scroll
    '';
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
