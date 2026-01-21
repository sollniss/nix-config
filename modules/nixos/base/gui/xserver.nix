{pkgs, ...}: {
  services = {
    xserver = {
      enable = true;

      xkb = {
        layout = "us";
        variant = "altgr-intl";
      };

      excludePackages = [pkgs.xterm];
      desktopManager.xterm.enable = false;
    };
  };
}
