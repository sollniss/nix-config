{ config, lib, ... }:
let
  port = 22;
  network = config.prefs.network;

  # Collect CIDRs from all defined subnets.
  subnetCidrs = map (s: s.cidr) (builtins.attrValues network.subnets);
  cidrCsv = builtins.concatStringsSep ", " subnetCidrs;
in
{
  config = lib.mkIf config.prefs.hosted.ssh.enable {
    services.openssh = {
      enable = true;
      openFirewall = false; # We manage the firewall rules ourselves below.
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        ListenAddress = "0.0.0.0";
      };
    };

    # Only allow SSH from known subnets.
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = ''
      ip saddr { ${cidrCsv} } tcp dport ${toString port} accept
      tcp dport ${toString port} drop
    '';
  };
}
