{
  inputs,
  pkgs,
  ...
}:
let
	# Terminal-only config, so no UI stuff needed.
  homeManagerModules = with inputs.self.homeManagerModules; [
    #base
  ];
in
{
  imports = homeManagerModules;

  home.username = "sollniss";
  home.homeDirectory = "/home/sollniss";
  home.stateVersion = "25.05";

  programs.bash = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    icons = "always";
  };

  programs.bat = {
    enable = true;
  };

  home.shellAliases = {
    cat = "bat";
    ls = "eza";
    ll = "eza -l";
    nixosbtw = "nix-shell -p fastfetch --run fastfetch";
  };

  # Extra packages.
  home.packages = with pkgs; [
    # development
    #gopls # Go LSP
    #nil # Nix LSP
    #nixd
  ];

  # Extra programs.
  programs.go = {
    enable = true;
    env.GOPATH = "code/go";
  };

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

    settings = {
      theme = "dark_plus";
    };

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

  programs.git = {
    enable = true;
		settings.user = {
      name = "sollniss";
      email = "sollniss@web.de";
    };
  };
}
