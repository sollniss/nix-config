{ config, ... }:
{
  programs.helix = {
    extraPackages = config.dev.nix.neededPackages;
    languages.language-server.nixd.config.nixd = config.dev.nix.nixdSettings;
    languages.language = [
      {
        name = "nix";
        language-servers = [ "nixd" ];
        formatter = {
          command = "nixfmt";
        };
        auto-format = true;
      }
    ];
  };
}
