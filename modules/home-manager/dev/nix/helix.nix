{config, ...}: {
  programs.helix = {
    extraPackages = config.dev.nix.neededPackages;
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
