# an independent failsafe SSH door on port 2222 in case the real bind locks me out.
# TODO: remove after I've confirmed the binding has no racing issues.
#
#   ssh -p 2222 root@192.168.1.101
{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = 2222;

  # Mirrors the main sshd policy, but as a static file so a future change to
  # the main config cannot break both doors at once. The host key is the one
  # ssh.nix generates, so clients see the same host identity on both ports.
  sshdConfig = pkgs.writeText "sshd-failsafe.conf" ''
    PermitRootLogin prohibit-password
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    AuthorizedKeysFile %h/.ssh/authorized_keys /etc/ssh/authorized_keys.d/%u
    HostKey /var/lib/ssh/ssh_host_ed25519_key
    UsePAM no
    AllowUsers root${lib.optionalString (config.prefs.user.name != null) " ${config.prefs.user.name}"}
  '';
in
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf config.prefs.hosted.ssh.enable {
    systemd.sockets.sshd-failsafe = {
      description = "Failsafe SSH socket (trial period)";
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = port;
        Accept = true;
        # A brute-force burst must not shut the failsafe door.
        TriggerLimitIntervalSec = 0;
      };
    };

    systemd.services."sshd-failsafe@" = {
      description = "Failsafe SSH per-connection daemon";
      serviceConfig = {
        ExecStart = "-${lib.getExe' config.services.openssh.package "sshd"} -i -f ${sshdConfig}";
        KillMode = "process";
        StandardInput = "socket";
        StandardError = "journal";
      };
    };

    # Same exposure policy as the main sshd: known subnets only.
    prefs.hosted.subnetOnlyPorts.tcp = [ port ];
  };
}
