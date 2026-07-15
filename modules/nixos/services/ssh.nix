{ config, lib, ... }:
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf config.prefs.hosted.ssh.enable {
    services.openssh = {
      enable = true;
      openFirewall = false; # We manage the firewall rules ourselves below.
      # Keep host keys outside /etc so they survive a read-only /etc overlay.
      hostKeys = [
        {
          path = "/var/lib/ssh/ssh_host_ed25519_key";
          type = "ed25519";
        }
        {
          path = "/var/lib/ssh/ssh_host_rsa_key";
          bits = 4096;
          type = "rsa";
        }
      ];
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        AllowUsers = [
          "root"
        ]
        ++ lib.optional (config.prefs.user.name != null) config.prefs.user.name;
        # DANGER: Changing this to listen only on local addresses causes lockout.
        # I've tried to force sshd binding the addresses after the interface comes online,
        # but that didn't work.
        # Might recheck this in the future, not really a fan of listening to all addresses
        # (even with the firewall settings).
        ListenAddress = "0.0.0.0";
      };
    };

    # Only allow SSH from known subnets.
    prefs.hosted.subnetOnlyPorts.tcp = [ 22 ];
  };
}
