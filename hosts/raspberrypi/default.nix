{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
    inputs.self.modules.nixos.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    nixos.hostname = "raspberrypi";

    hosted = {
      ssh.enable = true;
      vpn.enable = true;
      dns.enable = true;
      dhcp.enable = true;
      slaac.enable = false;
      calendar.enable = true;
      photos = {
        enable = true;
        # Read-only index over a folder on the NAS share: drop photos in over
        # SMB/NFS and they appear in Immich, no upload needed.
        externalLibrary = "/srv/nas/photos";
      };
      music = {
        enable = true;
        # Navidrome reads its library straight from a folder on the NAS share.
        musicFolder = "/srv/nas/music";
        # Second front-end over the same library, for UI comparison.
        feishin.enable = true;
      };
      nas = {
        enable = true;
        path = "/srv/nas";
      };
      sync = {
        enable = true;
        folders = {
          # Sync the phone's camera inbox directly onto the NAS and into immich.
          # Deletes propagate up.
          photos = "/srv/nas/photos/phone";
          # Ciphertext-only replicas
          keepass = "/mnt/pool/sync/keepass";
          memos = "/mnt/pool/sync/memos";
          # NAS media trees, backed up onto the desktop. The photos folder
          # above is nested in nas-photos and automatically excluded from it.
          nas-photos = "/srv/nas/photos";
          nas-music = "/srv/nas/music";
        };
      };
    };

    secrets = {
      # Copy from webui.
      ddclientPassword = "/var/lib/secrets/ddclient-password";
      # install -Dm0400 -o root -g root /dev/stdin /var/lib/secrets/samba-password
      sambaPassword = "/var/lib/secrets/samba-password";

      # Generated automatically.
      immichApiKey = "/var/lib/secrets/immich-api-key";
      wireguardPrivateKey = "/var/lib/secrets/wireguard-private-key";
    };
  };
}
