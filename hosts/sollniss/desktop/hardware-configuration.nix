{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  # Every subvolume of the root pool mounts the same decrypted device. zstd
  # reclaims a third or more of the nix store and costs nothing noticeable on
  # NVMe.
  subvol = name: {
    device = "/dev/mapper/cryptroot";
    fsType = "btrfs";
    options = [
      "subvol=${name}"
      "compress=zstd"
      "noatime"
    ];
  };
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sr_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # A passphrase prompt in the initrd unlocks the root pool; everything but the
  # ESP lives behind it. allowDiscards lets TRIM through to the SSD, and
  # bypassWorkqueues skips dm-crypt's queueing, which only ever slows NVMe down.
  boot.initrd.luks.devices.cryptroot = {
    # blkid -s UUID -o value /dev/nvme0n1p4
    device = "/dev/disk/by-uuid/e2ef8739-a66e-4363-8904-b00e2add48ca";
    allowDiscards = true;
    bypassWorkqueues = true;
  };

  fileSystems."/" = subvol "@";
  fileSystems."/nix" = subvol "@nix";
  fileSystems."/home" = subvol "@home";

  # The ESP is cleartext.
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8AED-62DC";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  # Encrypted swap under a fresh random key each boot.
  # Costs hibernation, which this machine does not use.
  swapDevices = [
    {
      # blkid -s PARTUUID -o value /dev/nvme0n1p3
      device = "/dev/disk/by-partuuid/2044eccf-f5a0-4bc6-9935-0c98d3f1e516";
      randomEncryption = true;
    }
  ];

  prefs.nixos.interface = "enp34s0";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    extraPackages = [ pkgs.nvidia-vaapi-driver ];
  };

  environment = {
    systemPackages = [ pkgs.libva-utils ];
    variables = {
      MOZ_DISABLE_RDD_SANDBOX = "1";
      NVD_BACKEND = "direct";
      LIBVA_DRIVER_NAME = "nvidia";
    };
  };

  # Load nvidia driver for Xorg and Wayland
  # For offloading `amdgpu` (AMD iGPU) or `modesetting` (Intel iGPU)  is also required,
  # otherwise the X-server will be running permanently on Nvidia.
  services.xserver.videoDrivers = [
    # "amdgpu"
    "nvidia"
  ];

  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = true;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = false;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
