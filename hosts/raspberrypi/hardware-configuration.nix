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

  # The NAS share, on the external SSD.
  #
  # Formatted, with the export in a subvolume of its own so it can be snapshotted
  # without dragging in anything else that later lands on this disk:
  #
  #   wipefs -a /dev/sda
  #   sfdisk /dev/sda <<< 'label: gpt
  #   ,,L'
  #   mkfs.btrfs -L nas /dev/sda1
  #   mount /dev/sda1 /mnt && btrfs subvolume create /mnt/nas && umount /mnt
  #   blkid -s UUID -o value /dev/sda1   # <- goes below
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/srv/nas" = {
    device = "/dev/disk/by-uuid/00000000-0000-0000-0000-000000000000"; # TODO: blkid
    fsType = "btrfs";
    options = [
      "subvol=nas"
      "compress=zstd"
      "noatime"

      # Clients write whatever they like into this share, over a protocol with no
      # notion of unix permissions. None of it may ever become a setuid binary, a
      # device node, or something this host will execute. Drop noexec if the share
      # ever needs to hold something runnable.
      "nosuid"
      "nodev"
      "noexec"

      # Never hold up the boot for a USB disk.
      # If it is missing, the mount fails.
      "nofail"
      "x-systemd.device-timeout=10"
    ];
  };

  # Detects bit rot early rather than at restore time, which is the entire reason
  # for putting the share on btrfs. Reads the whole disk, so keep it off-peak.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/srv/nas" ];
  };
}
