# Shared front-end for the web services hosted here (SOGo, Immich, ...).
#
# Imported by every module that adds a virtual host, so the hardening and the
# firewall rules below are stated once instead of once per service. Everything
# is keyed off services.nginx.enable, so it disappears with the last service
# that turns nginx on.
{
  config,
  lib,
  ...
}:
let
  subnets = builtins.attrValues config.prefs.network.subnets;

  # The nftables allowlist (prefs.hosted.subnetOnlyPorts below), restated at
  # the HTTP layer: loopback plus every known subnet, so a firewall change
  # alone cannot expose a vhost.
  allowed = [
    "127.0.0.1"
    "::1"
  ]
  ++ map (s: s.cidr) subnets
  ++ builtins.filter (c: c != null) (map (s: s.cidr6) subnets);
  allowRules = lib.concatMapStringsSep "\n" (c: "allow ${c};") allowed;
in
{
  imports = [ ./firewall.nix ];

  config = lib.mkIf config.services.nginx.enable {
    services.nginx = {
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      # The allowlist is inherited by every vhost and location,
      # but only those that carry no access directives of their
      # own: nginx replaces inherited allow/deny wholesale rather than
      # stacking them, so no location below this may ever say "allow all".
      # The assertion below turns any such directive into an eval failure.
      appendHttpConfig = ''
        ${allowRules}
        deny all;
      '';
    };

    # Guard the guarantee above: an allow/deny inside a vhost or location
    # would silently replace the inherited allowlist rather than add to it,
    # so fail the eval instead. The submodules have no dedicated access
    # options, so extraConfig is the only place such a directive can hide.
    assertions =
      let
        hasAccessDirective =
          s: builtins.any (l: builtins.match "[ \t]*(allow|deny)[ \t].*" l != null) (lib.splitString "\n" s);
        offenders = lib.concatLists (
          lib.mapAttrsToList (
            vhostName: vhost:
            lib.optional (hasAccessDirective vhost.extraConfig) "virtualHosts.\"${vhostName}\""
            ++ lib.concatLists (
              lib.mapAttrsToList (
                locName: loc:
                lib.optional (hasAccessDirective loc.extraConfig) "virtualHosts.\"${vhostName}\".locations.\"${locName}\""
              ) vhost.locations
            )
          ) config.services.nginx.virtualHosts
        );
      in
      [
        {
          assertion = offenders == [ ];
          message = ''
            nginx: allow/deny found in ${builtins.concatStringsSep ", " offenders}.
            Access directives in a vhost or location replace the http-level
            LAN/VPN allowlist (modules/nixos/services/nginx.nix) instead of
            adding to it. Remove them; the allowlist is inherited.
          '';
        }
      ];

    # Only allow HTTP access from known subnets.
    prefs.hosted.subnetOnlyPorts.tcp = [ 80 ];
  };
}
