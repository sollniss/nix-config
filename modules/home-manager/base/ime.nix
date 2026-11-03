{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:
{
  # Work around home-manager#10132 until home-manager#10136 is merged:
  # upstream's i18n.inputMethod unconditionally includes gtk2-immodule.cache in
  # home.packages, which fails to evaluate now that gtk2 is marked broken.
  disabledModules = [ "i18n/input-method/default.nix" ];
  imports = [
    (
      let
        upstream = import "${modulesPath}/i18n/input-method/default.nix" {
          inherit config pkgs lib;
        };
        hasGtk2 = (pkgs ? gtk2) && !(pkgs.gtk2.meta.broken or false);
        packages = upstream.config.content.home.packages;
      in
      upstream
      // {
        config = lib.mkIf config.i18n.inputMethod.enable (
          upstream.config.content
          // {
            home.packages =
              if !hasGtk2 && builtins.length packages == 3 then
                [
                  (builtins.elemAt packages 0)
                  (builtins.elemAt packages 2)
                ]
              else
                packages;
          }
        );
      }
    )
  ];

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
}
