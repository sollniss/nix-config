{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  # Zed downloads language servers on demand (prebuilt binaries from GitHub, or
  # npm packages run on its Node runtime), and there's no setting to turn that
  # off. The prebuilt ones can't exec on NixOS anyway. A server with
  # `binary.path` set is never fetched, so every server we use is pinned to a
  # nixpkgs build here (or in dev/<lang>/zed.nix).
  lspBinary = pkg: bin: arguments: {
    binary = {
      path = "${pkg}/bin/${bin}";
      inherit arguments;
    };
  };

  # Fallback for servers we didn't pin: hand Zed a Node/npm that fail, so it
  # reports Node as unavailable instead of installing and running npm packages.
  # (A broken `node.path` doesn't make Zed fall back to downloading Node.)
  blocked =
    name:
    pkgs.writeShellScriptBin name ''
      echo "${name} is disabled for Zed; add the language server declaratively" >&2
      exit 1
    '';

  # Zed's built-in prettier is npm-installed and runs on Zed's Node runtime,
  # which is blocked above. Format with the nixpkgs build instead.
  prettier = {
    prettier.allowed = false;
    formatter.external = {
      command = lib.getExe pkgs.prettier;
      arguments = [
        "--stdin-filepath"
        "{buffer_path}"
      ];
    };
  };
in
{
  programs.zed-editor = {
    enable = true;
    #package = inputs.zed-editor.packages.${pkgs.stdenv.hostPlatform.system}.default;
    #extraPackages = with pkgs; [];
    #installRemoteServer = true;

    enableMcpIntegration = config.programs.mcp.enable;

    extensions = [
      "log"
      # "color-highlight" # Broken.
      "lua"
      "sql"
      "toml"
      "make"
      "just"
    ];
    mutableUserSettings = false;
    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      format_on_save = "on";

      # Extensions are sandboxed WASM; these are what let them escape it to
      # download, `npm install` or exec arbitrary binaries. Grant none, so
      # extensions only run the servers configured below.
      granted_extension_capabilities = [ ];
      node = {
        path = lib.getExe (blocked "node");
        npm_path = lib.getExe (blocked "npm");
      };

      semantic_tokens = "combined";
      global_lsp_settings.semantic_token_rules = [
        {
          token_type = "type";
          token_modifiers = [ "defaultLibrary" ];
          style = [
            "type.builtin"
          ];
        }
        {
          token_type = "parameter";
          style = [
            "variable.parameter"
            "parameter"
            "variable.special"
            "variable"
          ];
        }
      ];

      agent_servers = lib.mkIf config.programs.claude-code.enable {
        "claude-acp" = {
          type = "custom";
          command = lib.getExe pkgs.claude-agent-acp;
          env = {
            CLAUDE_CODE_EXECUTABLE = lib.getExe config.programs.claude-code.package;
          };
        };
      };
      lsp = with pkgs; {
        basedpyright = lspBinary basedpyright "basedpyright-langserver" [
          "--stdio"
        ];
        bash-language-server = lspBinary bash-language-server "bash-language-server" [
          "start"
        ];
        eslint = lspBinary vscode-langservers-extracted "vscode-eslint-language-server" [
          "--stdio"
        ];
        json-language-server = lspBinary vscode-langservers-extracted "vscode-json-language-server" [
          "--stdio"
        ];
        lua-language-server = lspBinary lua-language-server "lua-language-server" [ ];
        just-lsp = lspBinary just-lsp "just-lsp" [ ];
        package-version-server = lspBinary package-version-server "package-version-server" [ ];
        ruff = lspBinary ruff "ruff" [
          "server"
        ];
        tailwindcss-language-server = lspBinary tailwindcss-language-server "tailwindcss-language-server" [
          "--stdio"
        ];
        taplo = lspBinary taplo "taplo" [
          "lsp"
          "stdio"
        ];
        vtsls = lspBinary vtsls "vtsls" [
          "--stdio"
        ];
        yaml-language-server = lspBinary yaml-language-server "yaml-language-server" [
          "--stdio"
        ];
        "vscode-html-language-server" =
          lspBinary vscode-langservers-extracted "vscode-html-language-server" [
            "--stdio"
          ]
          // {
            settings = {
              html = {
                format = {
                  indentInnerHtml = true;
                  contentUnformatted = "svg,script";
                  extraLiners = "div,p";
                };
              };
            };
          };
      };
      languages =
        lib.genAttrs [
          "CSS"
          "GraphQL"
          "JavaScript"
          "JSON"
          "JSONC"
          "Markdown"
          "SCSS"
          "TSX"
          "TypeScript"
          "YAML"
        ] (_: prettier)
        // {
          "HTML" = {
            prettier.allowed = false;
            formatter = "language_server";
          };
        };
    };
  };

  home.shellAliases = {
    zed = "zeditor";
  };
}
