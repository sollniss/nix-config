# Apply prefs.hosted.subnetOnlyPorts.
# Imported by every service module that declares ports there.
{ config, lib, ... }:
let
  cfg = config.prefs.hosted.subnetOnlyPorts;
  subnets = builtins.attrValues config.prefs.network.subnets;

  cidrs4 = map (s: s.cidr) subnets;
  cidrs6 = [ "fe80::/10" ] ++ builtins.filter (c: c != null) (map (s: s.cidr6) subnets);

  # ULA destinations are unreachable from the internet (fc00::/7 is unrouted),
  # so packets addressed to this host's ULAs are from a known subnet even when
  # sourced from a GUA.
  dstCidrs6 = builtins.filter (c: c != null) (map (s: s.cidr6) subnets);

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
        ip6 daddr { ${csv dstCidrs6} } ${proto} dport { ${portSet} } accept
        ${proto} dport { ${portSet} } drop
      ''
    );

  # Everything above rests on one property of the NixOS firewall: extraInputRules
  # is appended to the END of the input-allow chain, after the accept rules it
  # emits for allowedTCPPorts/allowedUDPPorts. A port opened through those is
  # therefore accepted before the drop each block above ends with is ever
  # reached, and the subnet restriction silently becomes a no-op.
  #
  # Every service module here must pass openFirewall = false and declare its ports
  # below instead. Fail the eval if it ever breaks.
  firewall = config.networking.firewall;

  # Merged across every interface, since allInterfaces holds the global lists
  # under "default" alongside any per-interface ones.
  fromAllInterfaces =
    field: lib.concatLists (lib.mapAttrsToList (_: iface: iface.${field}) firewall.allInterfaces);

  shadowed =
    proto: ports:
    let
      direct = fromAllInterfaces "allowed${proto}Ports";
      # Compared rather than expanded: a wide range would otherwise build a
      # 65535-element list at eval time.
      ranges = fromAllInterfaces "allowed${proto}PortRanges";
    in
    lib.filter (p: lib.elem p direct || lib.any (r: p >= r.from && p <= r.to) ranges) ports;

  clashes =
    map (p: "tcp/${toString p}") (shadowed "TCP" cfg.tcp)
    ++ map (p: "udp/${toString p}") (shadowed "UDP" cfg.udp);
in
{
  config = lib.mkIf (cfg.tcp != [ ] || cfg.udp != [ ]) {
    networking.nftables.enable = true;
    networking.firewall.extraInputRules = rules "tcp" cfg.tcp + rules "udp" cfg.udp;

    assertions = [
      {
        assertion = clashes == [ ];
        message = ''
          firewall: ${csv clashes} appears in both prefs.hosted.subnetOnlyPorts
          and networking.firewall.allowed{TCP,UDP}Ports.

          The latter is accepted earlier in the input-allow chain than the rules
          this module appends, so the drop that confines the port to the known
          subnets is never reached and the port is open to everything that can
          route to this host.

          This usually means a service module was left with openFirewall = true.
          Set it to false and declare the port in prefs.hosted.subnetOnlyPorts
          instead, which is what every module importing this one does.
        '';
      }
    ];
  };
}
