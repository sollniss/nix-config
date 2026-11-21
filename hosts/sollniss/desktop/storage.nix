# Encrypted data volumes
{
  lib,
  pkgs,
  ...
}:
let
  # blkid -s UUID -o value /dev/nvme0n1p2
  backupUuid = "7394c1e5-feea-4651-a40f-925e4d62b67d";
  # blkid -s UUID -o value /dev/nvme0n1p5
  vaultUuid = "27d3a3f7-df87-4c2a-9ba4-fdbc5a8a7533";

  backupKeyFile = "/var/lib/secrets/luks-backup.key";

  vaultMount = "/vault";
  btrfsOpts = [
    "compress=zstd"
    "noatime"
  ];

  vault = pkgs.writeShellApplication {
    name = "vault";
    runtimeInputs = with pkgs; [
      cryptsetup
      util-linux
    ];
    text = ''
      dev=/dev/disk/by-uuid/${vaultUuid}
      mapper=/dev/mapper/vault
      mount=${vaultMount}

      cmd="''${1-status}"

      # Only open and close touch dm-crypt and the mount table. status is two
      # stat calls against a 0555 mountpoint and world-readable /dev/mapper, so
      # asking after the vault should not cost a password prompt. Both halves
      # of a real operation are elevated together, up front, rather than
      # unlocking and then failing to mount.
      case "$cmd" in
        open | close)
          if [ "$(id -u)" -ne 0 ]; then
            exec sudo -- "$0" "$@"
          fi
          ;;
      esac

      case "$cmd" in
        open)
          [ -e "$mapper" ] || cryptsetup open --allow-discards "$dev" vault
          mountpoint -q "$mount" || mount -o ${lib.concatStringsSep "," btrfsOpts} "$mapper" "$mount"
          echo "vault: open at $mount"
          ;;
        close)
          ! mountpoint -q "$mount" || umount "$mount"
          [ ! -e "$mapper" ] || cryptsetup close vault
          echo "vault: locked"
          ;;
        status)
          if mountpoint -q "$mount"; then
            echo "vault: open at $mount"
            df -h --output=size,used,avail,pcent "$mount" | tail -n1
          elif [ -e "$mapper" ]; then
            echo "vault: unlocked but not mounted"
          else
            echo "vault: locked"
          fi
          ;;
        *)
          echo "usage: vault [open|close|status]" >&2
          exit 1
          ;;
      esac
    '';
  };
in
{
  # systemd's cryptsetup generator turns this into a unit that runs after the
  # root is mounted, which is where the keyfile lives. `discard` matches the
  # root pool's allowDiscards.
  #
  # vault is noauto, so nothing opens it at boot. The entry is there for
  # udisks: unlocking from the file manager then uses the same mapper name
  # (/dev/mapper/vault) as the vault script instead of luks-<uuid>.
  environment.etc.crypttab.text = ''
    backup /dev/disk/by-uuid/${backupUuid} ${backupKeyFile} luks,discard
    vault /dev/disk/by-uuid/${vaultUuid} none luks,discard,noauto
  '';

  # nofail plus a short device timeout: a backup volume that fails to unlock is
  # a thing to look into over coffee, not a reason to drop to an emergency
  # shell.
  fileSystems."/backup" = {
    device = "/dev/mapper/backup";
    fsType = "btrfs";
    options = btrfsOpts ++ [
      "nofail"
      "x-systemd.device-timeout=10s"
    ];
  };

  # Never mounted at boot (noauto). Declared so the file manager shows the
  # vault while it is open (gvfs hides mounts outside /media, /run/media and
  # $HOME unless fstab says x-gvfs-show), and so udisks mounts it at /vault
  # rather than /run/media. x-udisks-auth lets udisks mount a non-`user` fstab
  # entry after an admin prompt, the same bar as sudo in the vault script.
  fileSystems.${vaultMount} = {
    device = "/dev/mapper/vault";
    fsType = "btrfs";
    options = btrfsOpts ++ [
      "noauto"
      "nofail"
      "x-gvfs-show"
      "x-gvfs-name=Vault"
      "x-udisks-auth"
    ];
  };

  # /vault is never mounted at boot, make it unwritable.
  systemd.tmpfiles.rules = [
    "d ${vaultMount} 0555 root root -"
  ];

  environment.systemPackages = [
    vault
    pkgs.cryptsetup # for luksHeaderBackup, luksAddKey
  ];
}
