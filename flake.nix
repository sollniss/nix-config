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

  outputs =
    {
      nixpkgs,
      home-manager,
      catppuccin,
      ...
    }@inputs:
    {
      formatter.x86_64-linux =
        with nixpkgs.legacyPackages.x86_64-linux;
        treefmt.withConfig {
          runtimeInputs = [
            nixfmt
          ];

          settings = {
            on-unmatched = "info";
            tree-root-file = "flake.nix";

            formatter = {
              nixfmt = {
                command = "nixfmt";
                includes = [ "*.nix" ];
              };
            };
          };
        };
      # sudo nixos-rebuild switch --flake .#nixos
      # sudo nixos-rebuild switch --flake github:sollniss/nix-config#nixos
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          #./modules/prefs
          ./hosts/sollniss/desktop
          #catppuccin.nixosModules.catppuccin
        ];
      };

      nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./hosts/sollniss/wsl
          #catppuccin.nixosModules.catppuccin
        ];
      };

      # home-manager switch --flake .#terminal
      # home-manager switch --flake github:sollniss/nix-config#terminal
      homeConfigurations.terminal = home-manager.lib.homeManagerConfiguration {
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./hosts/sollniss/terminal
        ];
      };

      prefs = ./modules/prefs;
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
    };
}
