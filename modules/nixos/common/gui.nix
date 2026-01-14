{
  inputs,
  pkgs,
  ...
}: let
  nixosModules = with inputs.self.nixosModules; [
    core
  ];
in {
  imports = nixosModules;

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

    printing.enable = true;

    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security.rtkit.enable = true;
}
