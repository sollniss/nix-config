# Centralized Syncthing folder registry
#
# A Syncthing folder is shared state: every participating device must agree on
# the folder ID, or they sync nothing. This file is the one place those IDs
# live, next to which hosts (by their network.nix name) share each folder.
# Only the ID and the membership are global; every host picks its own local
# path for a folder in its own configuration.
#
# Device identities are per-host, so they live in network.nix (syncthingId),
# like wgPubKey and hostPubKey.
{
  folders = {
    keepass = {
      id = "crijs-3d7pa";
      hosts = [
        "nixos"
        "raspberrypi"
        "phone-d"
      ];
      untrusted = [ "raspberrypi" ];
    };
    photos = {
      id = "0zloo-2xerr";
      hosts = [
        "nixos"
        "raspberrypi"
        "phone-d"
      ];
    };
    memos = {
      id = "p7pmi-8794o";
      hosts = [
        "nixos"
        "raspberrypi"
        "phone-d"
      ];
      untrusted = [ "raspberrypi" ];
    };
    nas-photos = {
      id = "nas-photos";
      hosts = [
        "nixos"
        "raspberrypi"
      ];
      receiveOnly = [ "nixos" ];
    };
    nas-music = {
      id = "nas-music";
      hosts = [
        "nixos"
        "raspberrypi"
      ];
      receiveOnly = [ "nixos" ];
    };
  };
}
