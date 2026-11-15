{ config, lib, ... }:
let
  # modprobe hands the command to `/bin/sh -c`, where `false` is a builtin.
  mkDisableConfig = modules: lib.concatStringsSep "\n" (map (mod: "install ${mod} false") modules);
in
{
  # nix eval --json .#nixosConfigurations.nixos.config.boot.blacklistedKernelModules | jq -r '.[]' | xargs -r -I{} env MOD='{}' sh -c 'modinfo -b /run/booted-system/kernel-modules -k "$(uname -r)" "$MOD" >/dev/null 2>&1 || printf "%s\n" "$MOD"'
  boot.blacklistedKernelModules = lib.concatLists [
    # Linux Kernel Crypto API.
    # Most programs use user space APIs.
    #
    # https://copy.fail/
    # https://news.ycombinator.com/item?id=47956312
    [
      "af_alg"
      "algif_aead"
      "algif_hash"
      "algif_rng"
      "algif_skcipher"
    ]

    # IPSec.
    # These modules should not be used by anything else
    # and disabling them should break nothing.
    #
    # https://github.com/V4bel/dirtyfrag
    [
      "ah4"
      "ah6"
      "af_key"
      "esp4"
      "esp6"
      "xfrm_ipcomp"
      "xfrm_user"
    ]

    # Unused protocols
    [
      # SCTP - Stream Control Transmission Protocol
      "sctp"
      "sctp_diag"
      "xt_sctp"

      # TIPC - Transparent Inter Process Communication
      "tipc"
      "tipc_diag"

      "xt_dccp" # DCCP
      "rds" # RDS
      "appletalk"
      "can" # SocketCAN - Controller Area Network
    ]

    # Unused file systems
    [
      "adfs" # Acorn Disc Filing System
      "affs" # Amiga FFS
      "befs" # BeOS FS
      "ceph" # Ceph Distributed File System
      "coda" # Coda Kernel-Venus Interface
      "cramfs" # Cramfs - cram a filesystem onto a small ROM
      "ecryptfs" # Largely superseded by fscrypt / LUKS
      "efs" # Extent File System
      "freevxfs" # Veritas FS
      "gfs2" # Global FS
      "hfs" # Apple HFS
      "hfsplus" # Apple HFS+
      "jffs2" # Journaling Flash FS
      "jfs" # Journaled File System
      "kafs" # Kernel AFS
      "ksmbd" # In-kernel SMB server
      "minix" # minix fs
      "nilfs2" # New Implementation of a Log-structured File System
      "ocfs2" # Oracle Cluster File System 2
      "omfs" # Optimized MPEG Filesystem
      "orangefs" # OrangeFS, a scale-out network file system
      "romfs" # Read-Only Memory File System
      "rxrpc" # AFS dependency, main cause of Dirty Frag
      "ubifs" # Unsorted Block Image File System
      "ufs" # Universal Flash Storage
      "zonefs" # Zone filesystem for Zoned block devices
    ]

    # Network File System
    # These are required by clients only,
    # so we can blacklist them on the server.
    (
      [ "nfsv3" ]
      ++ lib.optionals config.prefs.hosted.nas.enable [
        "nfs"
        "nfsv4"
      ]
    )

    # Unused stuff
    [
      "nfc"
      "firewire-core"
      "thunderbolt"
      "usbip-core"
    ]
  ];

  # Userspace: Not a boundary against root, who can insmod.
  boot.extraModprobeConfig = mkDisableConfig config.boot.blacklistedKernelModules;

  # Kernel: not even root can lift it without a reboot.
  boot.kernelParams = [
    "module_blacklist=${
      lib.concatStringsSep "," (
        lib.unique (map (lib.replaceStrings [ "-" ] [ "_" ]) config.boot.blacklistedKernelModules)
      )
    }"
  ];
}
