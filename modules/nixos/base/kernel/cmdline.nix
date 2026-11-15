{ config, lib, ... }:
{
  # The kernel truncates its command line at COMMAND_LINE_SIZE (2048 on x86_64
  # and aarch64) and silently drops the rest, so a growing parameter (the
  # module blacklist in ./modules.nix above all) could lose entries. Fail the
  # eval instead. The bootloader appends init=<toplevel>/init. The toplevel's
  # path cannot be referenced from an assertion it contains (the toplevel is
  # "throw unless every assertion holds"), but its length is known anyway: the
  # hash is always 32 characters and the name is built from config values, so
  # this is exact, not an estimate.
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
}
