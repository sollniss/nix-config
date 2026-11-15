{ ... }:
{
  # Don't show nix generation picker.
  # Can be displayed by pressing any key during boot.
  boot.loader.timeout = 0;

  # No editing the kernel command line from the boot menu.
  boot.loader.systemd-boot.editor = false;
}
