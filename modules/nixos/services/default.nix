{
  dhcp = import ./dhcp.nix;
  dnscrypt = import ./dnscrypt.nix;
  docker = import ./docker.nix;
  sogo = import ./sogo.nix;
  ssh = import ./ssh.nix;
  unbound = import ./unbound.nix;
  wireguard = import ./wireguard.nix;
}
