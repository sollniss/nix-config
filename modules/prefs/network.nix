# Centralized network topology
#
# All host IPs, interfaces, gateways, and nameservers in one place.
# Hosts reference this file instead of hardcoding network values.
{
  # Subnets
  subnets = {
    lan = {
      cidr = "192.168.0.0/24";
      prefixLength = 24;
      gateway = "192.168.0.1";
    };
    vpn = {
      cidr = "10.100.0.0/24";
      prefixLength = 24;
      gateway = "10.100.0.1";
    };
  };

  # Managed hosts
  hosts = {
    nixos = {
      ip = "192.168.0.100";
      subnet = "lan";
      dns = [ "192.168.0.101" ];
      # Trust paths signed by the desktop's signing key for remote deployments.
      # sudo nix-store --generate-binary-cache-key nixos-desktop /etc/nix/signing-key.private /etc/nix/signing-key.public
      signingKey = "nixos-desktop:Zc1ZNwDzEr/fBkktS9yrdDCDavc/koH16xOawRnAEMo=";
      sshPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/3EVlnhOuYLxus+1lG83Vto2kv7nAt/XbnYoXtldNd";
      platform = "x86_64-linux";
    };
    raspberrypi = {
      ip = "192.168.0.101";
      subnet = "lan";
      dns = [
        "127.0.0.1"
        "::1"
      ];
      platform = "aarch64-linux";
      builder = "nixos";
    };
    phone-d = {
      ip = "10.100.0.2";
      subnet = "vpn";
      wgPubKey = "dVxRwJMIRkR5UmHnGT4V7rpEst2MfqJQ+qrY7LyNA1U=";
    };
    phone-m = {
      ip = "10.100.0.3";
      subnet = "vpn";
      wgPubKey = "rjtoRyh52G6smFCSWr7U6IdJEUuvEXtBdDFsgxwNnCU=";
    };
  };
}
