# nix build .#nixosConfigurations.raspberrypi-sd-image.config.system.build.sdImage
{ inputs, lib, ... }:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  fileSystems."/boot/firmware".options = lib.mkForce [
    "nofail"
    "noauto"
  ];
}
