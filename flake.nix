{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-wsl,
    home-manager,
    catppuccin,
    ...
  } @ inputs: {
    # sudo nixos-rebuild switch --flake .#nixos
    # sudo nixos-rebuild switch --flake github:sollniss/nix-config#nixos
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        vars = {
          username = "sollniss";
          hostname = "nixos";
        };
      };
      modules = [
        ./hosts/sollniss/desktop/configuration.nix
        catppuccin.nixosModules.catppuccin
      ];
    };

    nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        vars = {
          username = "sollniss";
          hostname = "nixos-wsl";
        };
      };
      modules = [
        nixos-wsl.nixosModules.default
        {
          system.stateVersion = "25.05";
          wsl.enable = true;
        }
        ./hosts/sollniss/wsl/configuration.nix
        catppuccin.nixosModules.catppuccin
      ];
    };

    # home-manager switch --flake .#terminal
    # home-manager switch --flake github:sollniss/nix-config#terminal
    homeConfigurations.terminal = home-manager.lib.homeManagerConfiguration {
      specialArgs = {
        inherit inputs;
        vars = {
          username = "sollniss";
        };
      };
      modules = [
        ./hosts/sollniss/terminal/home.nix
      ];
    };

    nixosModules = import ./modules/nixos;
    homeManagerModules = import ./modules/home-manager;
  };
}
