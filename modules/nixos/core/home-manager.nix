{ inputs, vars, ...}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    sharedModules = [inputs.plasma-manager.homeModules.plasma-manager];

    extraSpecialArgs = {
      inherit inputs vars;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };
}
