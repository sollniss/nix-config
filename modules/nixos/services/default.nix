{
  dhcp = import ./dhcp.nix;
  dnscrypt = import ./dnscrypt.nix;
  docker = import ./docker.nix;
  feishin = import ./feishin.nix;
  # A path, not `import`, unlike every other entry here: the service modules
  # pull this renderer in as the path ./firewall.nix, and the module system
  # only deduplicates paths. Exposing a value would apply it twice on a host
  # that imports both, duplicating extraInputRules (types.lines).
  firewall = ./firewall.nix;
  immich = import ./immich.nix;
  nas = import ./nas.nix;
  navidrome = import ./navidrome.nix;
  nginx = import ./nginx.nix;
  slaac = import ./slaac.nix;
  sogo = import ./sogo.nix;
  ssh = import ./ssh.nix;
  ssh-failsafe = import ./ssh-failsafe.nix;
  unbound = import ./unbound.nix;
  wireguard = import ./wireguard.nix;
}
