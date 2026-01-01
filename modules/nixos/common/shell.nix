{
  lib,
  ...
}:
{
  time = {
    timeZone = "Asia/Tokyo";
    hardwareClockInLocalTime = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "en_GB.UTF-8";
      LC_IDENTIFICATION = "en_GB.UTF-8";
      LC_MEASUREMENT = "en_GB.UTF-8";
      LC_MONETARY = "en_GB.UTF-8";
      LC_NAME = "en_GB.UTF-8";
      LC_NUMERIC = "en_GB.UTF-8";
      LC_PAPER = "en_GB.UTF-8";
      LC_TELEPHONE = "en_GB.UTF-8";
      LC_TIME = "en_GB.UTF-8";
    };
  };

  networking.networkmanager.enable = true;

  documentation = {
    enable = lib.mkForce false;
    dev.enable = lib.mkForce false;
    doc.enable = lib.mkForce false;
    info.enable = lib.mkForce false;
    nixos.enable = lib.mkForce false;

    man = {
      enable = lib.mkForce false;
      generateCaches = lib.mkForce false;
      man-db.enable = lib.mkForce false;
      mandoc.enable = lib.mkForce false;
    };
  };
}
