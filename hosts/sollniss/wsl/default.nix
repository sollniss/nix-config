{ inputs, ... }:
{
  imports = [
    inputs.self.modules.nixos.prefs
    ./configuration.nix
  ];

  prefs = {
    user.name = "sollniss";
    user.email = "sollniss@web.de";
    nixos.hostname = "nixos-wsl";
    profile.graphical.enable = false;

    # mkpasswd -m yescrypt > /var/lib/secrets/user-password
    # chown root:root /var/lib/secrets/user-password
    # chmod 0400 /var/lib/secrets/user-password
    secrets.userPassword = "/var/lib/secrets/user-password";
  };
}
