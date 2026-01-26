{ config, ... }:
{
  programs.zed-editor = {
    extraPackages = config.dev.nix.neededPackages;
    extensions = [ "nix" ];
    userSettings = {
      languages = {
        Nix = {
          language_servers = [ "nixd" ];
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              #command = "alejandra";
              #arguments = ["--quiet" "--"];
              command = "nixfmt";
            };
          };
        };
      };
    };
  };
}
