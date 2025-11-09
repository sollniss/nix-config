{ config, pkgs, ... }:

{
    home.username = "sollniss";
    home.homeDirectory = "/home/sollniss";
    home.stateVersion = "25.05";

    # this makes only firefox dark
    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    #gtk = {
    #    enable = true;
    #    theme = {
    #        name = "Breeze-Dark";
    #        package = pkgs.libsForQt5.breeze-gtk;
    #    };
    #};

    i18n.inputMethod = {
    enable = true;
        type = "fcitx5";
        fcitx5 = {
            waylandFrontend = true;

            addons = with pkgs; [
                fcitx5-mozc       # Japanese input method
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
        gopls
    ];

    imports = [
        ./progs/firefox.nix
    ];

    programs.bash = {
        enable = true;
    };

    programs.git = {
        enable = true;
        settings.user.name = "sollniss";
        settings.user.email = "sollniss@web.de";
    };

    programs.go = {
        enable = true;
        env.GOPATH = "code/go";
    };
}
