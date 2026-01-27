# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL
{
  inputs,
  config,
  ...
}:
let
  nixosModules = with inputs.self.nixosModules; [
    core
    base
    wsl
  ];
in
{
  #imports = [
  #  #./hardware-configuration.nix
  #] ++ nixosModules;

  imports = nixosModules;

  programs.git = {
    enable = true;
  };

  home-manager.users.${config.prefs.user.name} = {
    imports = [
      ./home.nix
    ];
  };
}
