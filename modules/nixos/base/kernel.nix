{ config, lib, ... }:
let
  mkDisableConfig =
    modules: lib.concatStringsSep "\n" (map (mod: "install ${mod} /bin/false") modules);
in
{
  # nix eval --json .#nixosConfigurations.nixos.config.boot.blacklistedKernelModules | jq -r '.[]' | xargs -r -I{} env MOD='{}' sh -c 'modinfo -b /run/booted-system/kernel-modules -k "$(uname -r)" "$MOD" >/dev/null 2>&1 || printf "%s\n" "$MOD"'
  boot.blacklistedKernelModules = [
    # Linux Kernel Crypto API.
    # Most programs use user space APIs.
    #
    # https://copy.fail/
    # https://news.ycombinator.com/item?id=47956312
    "af_alg"
    "algif_aead"
    "algif_hash"
    "algif_rng"
    "algif_skcipher"

    # IPSec.
    # These modules should not be used by anything else
    # and disabling them break nothing.
    #
    # https://github.com/V4bel/dirtyfrag
    "ah4"
    "ah6"
    "af_key"
    "esp4"
    "esp6"
    "xfrm_ipcomp"
    "xfrm_user"

    # Unused protocols

    # DCCP
    "xt_dccp"

    # SCTP
    "sctp"
    "sctp_diag"
    "xt_sctp"

    # RDS
    "rds"

    # TIPC
    "tipc"
    "tipc_diag"

    # Unused file systems
    "adfs" # Acorn Disc Filing System
    "affs" # Amiga FFS
    "befs" # BeOS FS
    "ceph" # Ceph Distributed File System
    "coda" # Coda Kernel-Venus Interface
    "cramfs" # Cramfs - cram a filesystem onto a small ROM
    "ecryptfs" # Largely superseded by fscrypt / LUKS
    "freevxfs" # Veritas FS
    "gfs2" # Global FS
    "hfs" # Apple HFS
    "hfsplus" # Apple HFS+
    "jffs2" # Journaling Flash FS
    "jfs" # Journaled File System
    "kafs" # Kernel AFS
    "minix"
    "nilfs2"
    "ocfs2"
    "orangefs"
    "romfs"
    "rxrpc" # AFS dependency, main cause of Dirty Frag
    "ubifs"
    "ufs"
    "zonefs"
  ];

  boot.extraModprobeConfig = mkDisableConfig config.boot.blacklistedKernelModules;

  boot.kernelModules = [
    "tcp_bbr"
    "sch_cake"
  ];
  boot.kernel.sysctl = {
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
  };
}
