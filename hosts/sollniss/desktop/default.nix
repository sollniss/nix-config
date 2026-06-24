{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.prefs
    ./hardware-configuration.nix
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    nixos.hostname = "nixos";
    profile.graphical.enable = true;

    secrets = {
      # sudo nix-store --generate-binary-cache-key nixos-desktop /var/lib/secrets/nix-signing-key /var/lib/secrets/nix-signing-key.public
      nixSigningKey = "/var/lib/secrets/nix-signing-key";
      # mkpasswd -m yescrypt > /var/lib/secrets/user-password
      # chown root:root /var/lib/secrets/user-password
      # chmod 0400 /var/lib/secrets/user-password
      userPassword = "/var/lib/secrets/user-password";
    };
  };
}
