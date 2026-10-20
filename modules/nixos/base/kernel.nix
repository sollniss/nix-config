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

  # The kernel truncates its command line at COMMAND_LINE_SIZE (2048 on x86_64
  # and aarch64) and silently drops the rest, so the blacklist above could lose
  # entries as it grows. Fail the eval instead. The bootloader appends
  # init=<toplevel>/init. The toplevel's path cannot be referenced from an
  # assertion it contains (the toplevel is "throw unless every assertion
  # holds"), but its length is known anyway: the hash is always 32 characters
  # and the name is built from config values, so this is exact, not an estimate.
  assertions =
    let
      limit = 2048;
      params = lib.concatStringsSep " " config.boot.kernelParams;
      initArg = "init=/nix/store/${lib.strings.replicate 32 "0"}-nixos-system-${config.system.name}-${config.system.nixos.label}/init";
      length = builtins.stringLength params + 1 + builtins.stringLength initArg;
    in
    [
      {
        assertion = length < limit;
        message = "kernel command line is ${toString length} bytes, over the ${toString limit}-byte COMMAND_LINE_SIZE; the kernel would truncate it.";
      }
    ];

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
    # Only root reads the kernel log, which can leak kernel addresses
    "kernel.dmesg_restrict" = 1;
    # No eBPF for unprivileged users (a recurring privilege-escalation vector),
    # and constant blinding for every JIT-compiled BPF program
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
    # userfaultfd only for privileged users; it is a common exploit primitive
    "vm.unprivileged_userfaultfd" = 0;
    # Don't let unprivileged users autoload TTY line disciplines
    "dev.tty.ldisc_autoload" = 0;
    # Extend the symlink/hardlink protection above to FIFOs and regular files
    # in world-writable sticky directories such as /tmp
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # No core dumps from setuid processes
    "fs.suid_dumpable" = 0;
  };
}
