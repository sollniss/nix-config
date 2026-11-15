{ lib, ... }:
{
  boot.kernelModules = [
    "tcp_bbr"
    "sch_cake"
  ];

  boot.kernel.sysctl = {
    # BBR+CAKE
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv6.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "cake";
    # Enable syn flood protection
    "net.ipv4.tcp_syncookies" = 1;
    # Implement RFC 1337 fix
    "net.ipv4.tcp_rfc1337" = 1;
    # Ignore bad ICMP errors
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
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
