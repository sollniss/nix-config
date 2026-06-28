{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./ai.nix
    ./helix.nix
    ./zed.nix
  ];

  options.dev.go.neededPackages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    readOnly = true;
    internal = true;
    default = with pkgs; [
      gopls
      gotools
      gofumpt
      golangci-lint
      delve
    ];
  };

  config.programs.go = {
    enable = true;
    env = {
      GOPATH = "${config.xdg.dataHome}/go";
    };
  };

  config.home.sessionPath = [
    "${config.xdg.dataHome}/go/bin"
  ];

  config.home.sessionVariables = {
    CGO_ENABLED = "0";
  };
}
