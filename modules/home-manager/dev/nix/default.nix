{
  config,
  osConfig ? null,
  lib,
  pkgs,
  ...
}:
let
  flake = ''(builtins.getFlake "${config.home.homeDirectory}/nix-config")'';
  # The nixosConfigurations attribute to complete against: this host's, which
  # is named after its hostname in flake.nix. Standalone HM has no osConfig
  # and falls back to the desktop.
  host = if osConfig != null then osConfig.networking.hostName else "nixos";
in
{
  imports = [
    ./ai.nix
    ./helix.nix
    ./zed.nix
  ];

  options.dev.nix.neededPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    readOnly = true;
    default = with pkgs; [
      nixd
      #alejandra
      nixfmt
    ];
  };

  # Option sets nixd completes against. nixd offers both sets everywhere, it
  # can't tell a NixOS module from a home-manager one.
  options.dev.nix.nixdSettings = lib.mkOption {
    type = lib.types.attrs;
    readOnly = true;
    internal = true;
    default = {
      nixpkgs.expr = "import ${flake}.inputs.nixpkgs { }";
      options = {
        nixos.expr = "${flake}.nixosConfigurations.${host}.options";
        # The user's evaluated options, so modules imported per user (prefs,
        # dev, theme) complete too, not just upstream home-manager.
        home-manager.expr = "${flake}.nixosConfigurations.${host}.options.home-manager.users.valueMeta.attrs.${config.home.username}.configuration.options";
      };
    };
  };
}
