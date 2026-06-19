{ config, lib, ... }:
let
  mkDisableConfig =
    modules: lib.concatStringsSep "\n" (map (mod: "install ${mod} /bin/false") modules);
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
      "nfs" # Network File System
      "nfsv3"
      "nfsv4"
      "ocfs2" # Oracle Cluster File System 2
      "omfs" # Optimized MPEG Filesystem
      "orangefs" # OrangeFS, a scale-out network file system
      "romfs" # Read-Only Memory File System
      "rxrpc" # AFS dependency, main cause of Dirty Frag
      "ubifs" # Unsorted Block Image File System
      "ufs" # Universal Flash Storage
      "zonefs" # Zone filesystem for Zoned block devices
    ]

    # Unused stuff
    [
      "nfc"
      "firewire-core"
      "thunderbolt"
      "usbip-core"
    ]
  ];

  boot.extraModprobeConfig = mkDisableConfig config.boot.blacklistedKernelModules;

  boot.kernelModules = [
    "tcp_bbr"
    "sch_cake"
  ];
  boot.kernel.sysctl = {
    # Disable the magic SysRq key
    "kernel.sysrq" = 0;
    # Provide protection from ToCToU races
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    # Enable syn flood protection
    "net.ipv4.tcp_syncookies" = 1;
    # Implement RFC 1337 fix
    "net.ipv4.tcp_rfc1337" = 1;
    # Ignore bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    # BBR+CAKE
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv6.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    # Hide kernel pointers from all users
    "kernel.kptr_restrict" = 2;
    # Reverse path filtering (anti-spoofing)
    # Managed by networking.firewall.checkReversePath; mkDefault allows
    # modules (e.g. VPN) to switch to loose mode (rp_filter=2).
    "net.ipv4.conf.all.rp_filter" = lib.mkDefault 1;
    "net.ipv4.conf.default.rp_filter" = lib.mkDefault 1;
    # Disable ICMP redirects
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };
}
