{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  # polkitd only reads actions from a fixed set of system directories (on
  # NixOS: /run/current-system/sw/share/polkit-1/actions), never from the
  # per-user profiles useUserPackages installs into. Link every Home Manager
  # user's actions into the system profile so apps installed through Home
  # Manager (e.g. KeePassXC's Quick Unlock) can still be authorized.
  environment.systemPackages = lib.mapAttrsToList (
    name: hmConfig:
    pkgs.runCommandLocal "home-manager-polkit-actions-${name}" { } ''
      mkdir -p $out/share/polkit-1/actions
      src=${hmConfig.home.path}/share/polkit-1/actions
      if [ -d "$src" ]; then
        for f in "$src"/*.policy; do
          ln -s "$(readlink -f "$f")" $out/share/polkit-1/actions/
        done
      fi
    ''
  ) config.home-manager.users;

  # NixOS restarts polkitd whenever system.path changes, and with the link
  # above that is any Home Manager package change too. A restarted polkitd
  # forgets every registered authentication agent, and cosmic-osd registers
  # only once at session start, so after a rebuild every polkit prompt fails
  # until the next login. A reload (SIGHUP) rereads actions and rules but
  # keeps the agents, so reload on system.path changes instead.
  systemd.services.polkit = {
    restartTriggers = lib.mkForce [ ];
    reloadTriggers = [ config.system.path ];
  };
}
