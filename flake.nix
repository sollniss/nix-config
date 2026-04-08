{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
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
    let
      hostPlatforms = {
        nixos = "x86_64-linux";
        nixos-wsl = "x86_64-linux";
        raspberrypi = "aarch64-linux";
      };
    in
    {
      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system:
        with nixpkgs.legacyPackages.${system};
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
        }
      );
      # sudo nixos-rebuild switch --flake .#nixos
      # sudo nixos-rebuild switch --flake github:sollniss/nix-config#nixos
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs hostPlatforms;
        };
        modules = [
          #./modules/prefs
          ./hosts/sollniss/desktop
          #catppuccin.nixosModules.catppuccin
        ];
      };

      nixosConfigurations.nixos-wsl = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs hostPlatforms;
        };
        modules = [
          ./hosts/sollniss/wsl
          #catppuccin.nixosModules.catppuccin
        ];
      };

      # nixos-rebuild switch --flake .#raspberrypi --target-host root@192.168.0.101
      #
      # Build SD image:
      # nix build .#nixosConfigurations.raspberrypi.config.system.build.sdImage
      # lsblk  ---------------------------------------------------------
      # sudo umount /run/media/XXXXXXX                               ↓↓↓
      # zstd -d result/sd-image/*.img.zst --stdout | sudo dd of=/dev/sda bs=4M status=progress conv=fsync
      # sudo umount /dev/sda1 /dev/sda2
      # sudo eject /dev/sda
      nixosConfigurations.raspberrypi = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs hostPlatforms;
        };
        modules = [
          ./hosts/raspberrypi
        ];
      };

      # home-manager switch --flake .#terminal
      # home-manager switch --flake github:sollniss/nix-config#terminal
      homeConfigurations.terminal = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
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
