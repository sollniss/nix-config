{
  ...
}:
{
  services.syncthing = {
    enable = true;
    settings = {
      options = {
        globalAnnounceEnabled = false;
        localAnnounceEnabled = true;
        # Whether the user has accepted to submit anonymous usage data.
        # The default, 0, mean the user has not made a choice, and Syncthing will ask at some point in the future.
        # "-1" means no, a number above zero means that that version of usage reporting has been accepted.
        urAccepted = -1;
      };
    };
  };
}
