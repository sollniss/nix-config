{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./helix.nix
    ./zed.nix
  ];

  options.dev.go.neededPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    readOnly = true;
    default = with pkgs; [
      gopls
      gotools
      gofumpt
      golangci-lint
      delve
      gcc
    ];
  };

  config.programs.go = {
    enable = true;
    env = {
      GOPATH = "${config.xdg.dataHome}/go";
    };
  };
}
