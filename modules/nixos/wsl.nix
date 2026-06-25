{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl = {
    enable = true;
    defaultUser = config.prefs.user.name;
    startMenuLaunchers = true;
    interop = {
      includePath = false;
      register = true;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  services = {
    printing.enable = lib.mkForce false;
    xserver.enable = lib.mkForce false;
    openssh.enable = lib.mkForce false;

    # resolv.conf is managed by WSL
    resolved.enable = lib.mkForce false;
  };

  networking = {
    # Managed by Windows
    useDHCP = lib.mkForce false;
    firewall.enable = lib.mkForce false;
    # Wait online service can cause issues in WSL
    networkmanager.enable = lib.mkForce false;
    # wpa_supplicant is not needed in WSL and can cause activation failures.
    wireless.enable = lib.mkForce false;
  };

  # Allow opening files and links in Windows from WSL
  environment.variables.BROWSER = lib.mkForce "wsl-open";
  environment.systemPackages = with pkgs; [
    wsl-open
  ];

  # Revert some global settings.

  # zram and elevated swappiness are counterproductive in WSL.
  zramSwap.enable = lib.mkForce false;
  boot.kernel.sysctl."vm.swappiness" = lib.mkForce 60;

  users.mutableUsers = lib.mkForce true;
  services.userborn.enable = lib.mkForce false;
}
