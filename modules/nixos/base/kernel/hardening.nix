{ ... }:
{
  # No kexec, no hibernation: the running kernel can only change through a
  # reboot (deploys only add a boot entry). Nothing here hibernates anyway: the
  # desktop's swap is randomly encrypted per boot, the Pi has none on disk.
  # A remote reinstall that kexecs into an installer (nixos-anywhere) needs
  # this off and a reboot first.
  security.protectKernelImage = true;

  boot.kernel.sysctl = {
    # Disable the magic SysRq key
    "kernel.sysrq" = 0;
    # Hide kernel pointers from all users
    "kernel.kptr_restrict" = 2;
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
    # Provide protection from ToCToU races
    "fs.protected_hardlinks" = 1;
    "fs.protected_symlinks" = 1;
    # Extend the symlink/hardlink protection above to FIFOs and regular files
    # in world-writable sticky directories such as /tmp
    "fs.protected_fifos" = 2;
    "fs.protected_regular" = 2;
    # No core dumps from setuid processes
    "fs.suid_dumpable" = 0;
  };
}
