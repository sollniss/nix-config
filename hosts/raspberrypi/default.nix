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
