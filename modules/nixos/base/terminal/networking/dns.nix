{...}: let
  dnsServers = [
    # Quad9
    "2620:fe::fe"
    "2620:fe::9"
    "9.9.9.9"
    "149.112.112.112"

    # Cloudflare
    #"2606:4700:4700::1111"
    #"2606:4700:4700::1001"
    #"1.1.1.1"
    #"1.0.0.1"
  ];
in {
  networking = {
    hostName = "nixos";
    nameservers = dnsServers;
    networkmanager = {
      # Either of these two should be enough to force the nameservers.
      # Set both just to be extra sure.
      dns = "none";
      insertNameservers = dnsServers;
    };
  };
}
