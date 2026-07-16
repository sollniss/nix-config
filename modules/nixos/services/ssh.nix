{ config, lib, ... }:
let
  network = config.prefs.network;
  hostname = config.prefs.nixos.hostname;
  self = if hostname != null then network.hosts.${hostname} or null else null;
in
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
        ListenAddress = if self != null then self.ip else "0.0.0.0";
      };
    };

    # allow bind() to addresses this host doesn't own (yet)
    # to prevent lockout because of races.
    boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

    # never let a transient start failure escalate into systemd
    # giving up on sshd forever. start-limit-hit can only be cleared from a
    # console, which a headless host doesn't have.
    systemd.services.sshd = {
      unitConfig.StartLimitIntervalSec = 0;
      serviceConfig.RestartSec = 5;
    };

    # Only allow SSH from known subnets.
    prefs.hosted.subnetOnlyPorts.tcp = [ 22 ];
  };
}
