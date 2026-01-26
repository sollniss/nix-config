{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./helix.nix
    ./zed.nix
  ];

  options.dev.nix.neededPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    readOnly = true;
    default = with pkgs; [
      nixd
      alejandra
      #nixfmt
    ];
  };
}
