{
  config,
  pkgs,
  ...
}: {
  programs.helix = {
    extraPackages = config.dev.go.neededPackages;

    languages.language = [
      {
        name = "nix";
        language-servers = ["nixd"];
        formatter = {
          command = "alejandra";
        };
        auto-format = true;
      }
    ];
  };
}
