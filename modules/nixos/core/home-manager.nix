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
}
