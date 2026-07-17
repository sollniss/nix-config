{
  dhcp = import ./dhcp.nix;
  dnscrypt = import ./dnscrypt.nix;
  docker = import ./docker.nix;
  immich = import ./immich.nix;
  nas = import ./nas.nix;
  navidrome = import ./navidrome.nix;
  nginx = import ./nginx.nix;
  sogo = import ./sogo.nix;
  ssh = import ./ssh.nix;
  ssh-failsafe = import ./ssh-failsafe.nix;
  unbound = import ./unbound.nix;
  wireguard = import ./wireguard.nix;
}
