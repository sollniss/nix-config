# Paths, not `import`ed values: the module system deduplicates modules by path,
# so a service module may import a sibling (./nginx.nix, ./firewall.nix) that a
# host also lists from here without it being applied twice.
{
  dhcp = ./dhcp.nix;
  dnscrypt = ./dnscrypt.nix;
  docker = ./docker.nix;
  feishin = ./feishin.nix;
  firewall = ./firewall.nix;
  immich = ./immich.nix;
  nas = ./nas.nix;
  navidrome = ./navidrome.nix;
  nginx = ./nginx.nix;
  slaac = ./slaac.nix;
  sogo = ./sogo.nix;
  ssh = ./ssh.nix;
  syncthing = ./syncthing.nix;
  wireguard = ./wireguard.nix;
}
