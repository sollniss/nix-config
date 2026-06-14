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

  programs.mergiraf = {
    enable = true;
    enableGitIntegration = config.programs.git.enable;
    enableJujutsuIntegration = config.programs.jujutsu.enable;
  };

  programs.jujutsu = {
    enable = true;
    settings = {
      ui = {
        diff-formatter = [
          (lib.getExe config.programs.difftastic.package)
          "--color=always"
          "$left"
          "$right"
        ];
        # On graphical hosts override mergiraf (set by programs.mergiraf) with
        # the interactive meld GUI; headless hosts keep mergiraf.
        merge-editor = lib.mkIf config.prefs.profile.graphical.enable (
          lib.mkForce [
            (lib.getExe pkgs.meld)
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
          ]
        );
      };
    };
  };

  programs.claude-code = {
    enable = true;
  };
}
