{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      plasma-manager,
      ...
    } @ inputs:
    {
			# sudo nixos-rebuild build --flake .#nixos
			# sudo nixos-rebuild build --flake github:sollniss/nix-config#nixos
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/sollniss/desktop/configuration.nix
        ];
      };

			# home-manager build --flake .#terminal
			# home-manager build --flake github:sollniss/nix-config#terminal
			homeConfigurations.terminal = home-manager.lib.homeManagerConfiguration {
				specialArgs = { inherit inputs; };
        modules = [
          ./hosts/sollniss/terminal/home.nix
        ];
			};

      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
    };
}
