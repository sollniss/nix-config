{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.packages = (
    with pkgs;
    [
      devenv
    ]
    ++ lib.lists.optionals config.prefs.profile.graphical.enable [
      gg-jj # jujutsu gui
      meld # merge gui
    ]
  );

  programs.jq = {
    enable = true;
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      ui = {
        diff-formatter = [
          "difft"
          "--color=always"
          "$left"
          "$right"
        ];
        merge-editor = lib.mkIf config.prefs.profile.graphical.enable [
          "meld"
          "$left"
          "$base"
          "$right"
          "-o"
          "$output"
        ];
      };
    };
  };

  programs.claude-code = {
    enable = true;
  };
}
