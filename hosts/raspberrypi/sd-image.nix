# nix build .#nixosConfigurations.raspberrypi-sd-image.config.system.build.sdImage
{ inputs, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
}
