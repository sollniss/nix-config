{ inputs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = import ../../overlays { inherit inputs; };
}
