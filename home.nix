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
