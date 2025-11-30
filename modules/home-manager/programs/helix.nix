{
  pkgs,
  ...
}:
{
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      # Common stuff
      bash-language-server
      helix-gpt

      # Go
      gopls
      gotools
      golangci-lint
      golangci-lint-langserver

      # Nix
      #nil
      nixd
    ];

    languages = {
      language-server.biome = {
        command = "biome";
        args = [ "lsp-proxy" ];
      };

      language-server.gpt = {
        command = "helix-gpt";
        args = [ "--handler" "copilot" ];
      };

      language = [
        {
          name = "go";
          language-servers = [ "gopls" "golangci-lint-lsp" "gpt" ];
          auto-format = true;
        }
        {
          name = "nix";
          language-servers = [ "nixd" "gpt" ];
          auto-format = true;
        }
      ];
    };
  };
}
