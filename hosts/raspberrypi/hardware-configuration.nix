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

  # External SSD.
  boot.supportedFilesystems = [ "btrfs" ];

  fileSystems."/srv/nas" = {
    device = "/dev/disk/by-uuid/65cf1d59-f7cd-4de2-9b8f-41cfb021c92e";
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

  # Immich's own storage (thumbnails, transcoded video, database backups, etc)
  fileSystems."/var/lib/immich" = {
    device = "/dev/disk/by-uuid/65cf1d59-f7cd-4de2-9b8f-41cfb021c92e";
    fsType = "btrfs";
    options = [
      "subvol=immich"
      "compress=zstd"
      "noatime"
      "nosuid"
      "nodev"
      "nofail"
      "x-systemd.device-timeout=10"
    ];
  };

  # Navidrome's own storage (SQLite database plus cover-art and transcode cache).
  fileSystems."/var/lib/navidrome" = {
    device = "/dev/disk/by-uuid/65cf1d59-f7cd-4de2-9b8f-41cfb021c92e";
    fsType = "btrfs";
    options = [
      "subvol=navidrome"
      "compress=zstd"
      "noatime"
      "nosuid"
      "nodev"
      "nofail"
      "x-systemd.device-timeout=10"
    ];
  };

  # Detects bit rot early rather than at restore time, which is the entire reason
  # for putting the share on btrfs. Scrub works at the filesystem level, so the
  # one entry below covers every subvolume on this disk. Reads the whole disk,
  # so keep it off-peak.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/srv/nas" ];
  };

  # Enable TRIM on the SSD. The RTL9210B bridge in the enclosure supports the
  # SCSI UNMAP command (Logical Block Provisioning VPD reports LBPU=1), but
  # READ CAPACITY(16) reports lbpme=0, so Linux's sd driver defaults to
  # provisioning_mode=full and disables discard. Forcing "unmap" is safe here
  # precisely because LBPU=1 is confirmed; verified on this hardware (fstrim
  # trims the full 465 GiB cleanly, no bus resets). Matches on the USB IDs, so
  # the powered-hub hop in the chain does not defeat it.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="scsi_disk", \
      ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="9210", \
      ATTR{provisioning_mode}="unmap"
  '';

  # Batch the discards into a weekly fstrim rather than mounting with
  # discard=async: continuous discard would need the udev rule applied before
  # the mount (a boot-order race), and UNMAP over a USB bridge is happier
  # batched than fired on every delete.
  services.fstrim.enable = true;
}
