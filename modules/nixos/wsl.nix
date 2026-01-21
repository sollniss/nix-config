{
  inputs,
  vars,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl = {
    enable = true;
    defaultUser = vars.username;
    startMenuLaunchers = true;
    interop = {
      includePath = false;
      register = true;
    };
  };

  services = {
    xserver.enable = lib.mkForce false;
    openssh.enable = lib.mkForce false;

    # resolv.conf is managed by WSL
    resolved.enable = lib.mkForce false;
  };

  networking = {
    # Managed by Windows
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
}
