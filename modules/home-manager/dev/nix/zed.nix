{config, ...}: {
  programs.zed-editor = {
    extraPackages = config.dev.go.neededPackages;
    extensions = ["nix"];
    userSettings = {
      languages = {
        Nix = {
          language_servers = ["nixd"];
          tab_size = 2;
          format_on_save = "on";
          formatter = {
            external = {
              command = "alejandra";
              #command = "nixfmt";
              #arguments = ["--quiet" "--"];
            };
          };
        };
      };
    };
  };
}
