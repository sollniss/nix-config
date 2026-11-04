{
  config,
  pkgs,
  lib,
  ...
}:
{
  i18n.inputMethod = {
    enable = config.prefs.profile.graphical.enable;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;

      fcitx5-with-addons = pkgs.qt6Packages.fcitx5-with-addons.override { withConfigtool = false; };
      addons = with pkgs; [
        fcitx5-mozc # Japanese input method
      ];

      settings = {
        inputMethod = {
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
        globalOptions = {
          "Hotkey/TriggerKeys" = {
            "0" = "Alt+Shift_L";
          };
        };
      };
    };
  };

  home.sessionVariables.XMODIFIERS = lib.mkForce "";

  # With waylandFrontend, Qt falls back to text-input-v3, and fcitx5 then grabs the
  # keyboard via input-method-v2 whenever a Qt text field has focus. cosmic-comp
  # refuses xdg_popup grabs while any foreign keyboard grab is active and sends
  # popup_done immediately, so Qt menus (KeePassXC, Picard) won't open. Talking
  # to fcitx over D-Bus avoids the keyboard grab entirely.
  home.sessionVariables.QT_IM_MODULE = lib.mkIf config.i18n.inputMethod.enable "fcitx";
}
