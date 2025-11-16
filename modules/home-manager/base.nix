{
  pkgs,
  ...
}:
{
  # IME
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;

      addons = with pkgs; [
        fcitx5-mozc # Japanese input method
      ];

      settings.inputMethod = {
        GroupOrder = {
          "0" = "Default";
        };
        "Groups/0" = {
          Name = "Default";
          "Default Layout" = "us";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us";
          Layout = "";
        };
        "Groups/0/Items/1" = {
          Name = "mozc";
          Layout = "";
        };
      };
    };
  };

  home.packages = with pkgs; [
    # development
    gopls # Go LSP
    nil # Nix LSP

    vlc
    signal-desktop
    anki
  ];

  programs.bash = {
    enable = true;
  };

  programs.git = {
    enable = true;
  };

  programs.go = {
    enable = true;
    env.GOPATH = "code/go";
  };
}
