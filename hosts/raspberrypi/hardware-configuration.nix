{ ... }:
{
  # Use extlinux as bootloader since there is no GRUB on the Pi.
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # Device tree for Pi 4.
  hardware.deviceTree.filter = "bcm2711-rpi-*.dtb";

  # Essential kernel modules for Pi 4.
  boot.initrd.availableKernelModules = [
    "pcie-brcmstb"
    "reset-raspberrypi"
    "xhci_pci" # USB 3.0
    "usbhid"
  ];

  prefs.nixos.interface = "end0";

  nixpkgs.hostPlatform = "aarch64-linux";

  # Broadcom WiFi/Bluetooth firmware.
  hardware.enableRedistributableFirmware = true;
}
