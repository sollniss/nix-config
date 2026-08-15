{ config, ... }:
{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = true;
        relaysEnabled = false;
        # Disable UPnP/NAT-PMP mapping
        natEnabled = false;
        # Whether the user has accepted to submit anonymous usage data.
        # The default, 0, mean the user has not made a choice, and Syncthing will ask at some point in the future.
        # "-1" means no, a number above zero means that that version of usage reporting has been accepted.
        urAccepted = -1;

        listenAddresses = [
          "tcp://:${toString config.prefs.sync.port}"
          "quic://:${toString config.prefs.sync.port}"
        ];
        localAnnouncePort = config.prefs.sync.discoveryPort;
        localAnnounceMCAddr = "[ff12::8384]:${toString config.prefs.sync.discoveryPort}";
      };
    };
  };
}
