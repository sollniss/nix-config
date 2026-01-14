{pkgs, ...}: {
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
          "Default Layout" = "us-altgr-intl";
          DefaultIM = "mozc";
        };
        "Groups/0/Items/0" = {
          Name = "keyboard-us-altgr-intl";
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
    vlc
    signal-desktop
    #anki
  ];

  home.sessionVariables.ANKI_WAYLAND = "1";
}
