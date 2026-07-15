# Apply prefs.hosted.subnetOnlyPorts.
# Imported by every service module that declares ports there.
{ config, lib, ... }:
let
  cfg = config.prefs.hosted.subnetOnlyPorts;
  subnets = builtins.attrValues config.prefs.network.subnets;

  cidrs4 = map (s: s.cidr) subnets;
  cidrs6 = [ "fe80::/10" ] ++ builtins.filter (c: c != null) (map (s: s.cidr6) subnets);

  csv = builtins.concatStringsSep ", ";

  rules =
    proto: ports:
    lib.optionalString (ports != [ ]) (
      let
        portSet = csv (map toString (lib.unique ports));
      in
      ''
        ip saddr { ${csv cidrs4} } ${proto} dport { ${portSet} } accept
        ip6 saddr { ${csv cidrs6} } ${proto} dport { ${portSet} } accept
        ${proto} dport { ${portSet} } drop
      ''
    );
in
{
  config = lib.mkIf (cfg.tcp != [ ] || cfg.udp != [ ]) {
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = rules "tcp" cfg.tcp + rules "udp" cfg.udp;
  };
}
