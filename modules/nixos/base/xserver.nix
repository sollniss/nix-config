{pkgs, ...}: {
  services = {
    xserver = {
      enable = false;

      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };

      excludePackages = [pkgs.xterm];
      desktopManager.xterm.enable = false;
    };
  };
}
