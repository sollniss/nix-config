{ config, lib, ... }:
{
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };

  # Tuning for swap on zram.
  # https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  boot.kernel.sysctl = lib.mkIf config.zramSwap.enable {
    # Swapping to zram is cheaper than dropping page cache that has to be
    # reread from disk, so prefer it.
    "vm.swappiness" = 180;
    # Read one page from swap at a time (2^0) instead of 8. Readahead only pays
    # off on seeking disks; on zram it decompresses pages nobody asked for.
    "vm.page-cluster" = 0;
    # Don't temporarily raise the free-memory target after fragmentation
    # events. With zram that extra reclaim is just compression churn.
    "vm.watermark_boost_factor" = 0;
    # Start background reclaim at 1.25% of RAM free instead of 0.1%, so
    # allocations rarely have to stall in direct reclaim.
    "vm.watermark_scale_factor" = 125;
  };
}
