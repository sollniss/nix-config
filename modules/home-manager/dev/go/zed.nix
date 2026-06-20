{ config, pkgs, ... }:
let
  # Zed's built-in Go debugger always launches its own `delve-shim-dap` adapter
  # (a stdio DAP server that spawns `dlv` in a terminal and proxies to it), and
  # downloads a prebuilt build of it. That generic-linux binary can't exec on
  # NixOS, so debugging fails ("debugger shutdown unexpectedly", or hangs).
  #
  # Zed offers no way to point at a different adapter (`dap.Delve.binary` sets
  # the *dlv* path the shim runs, not the shim itself). So instead we build the
  # shim from source and drop it at the exact path Zed expects, so Zed uses ours
  # and never downloads one. Zed writes each version into its own `_v<ver>` dir
  # and never overwrites ours; if upstream bumps the version, Zed downloads the
  # new one, which simply fails to exec on NixOS (visible breakage, never silent
  # execution of downloaded code) — bump `version`/`rev`/hashes below to fix.
  delve-shim-dap = pkgs.rustPlatform.buildRustPackage {
    pname = "delve-shim-dap";
    version = "0.0.4";
    src = pkgs.fetchFromGitHub {
      owner = "zed-industries";
      repo = "delve-shim-dap";
      rev = "b3c7c82ece293a40ee8dba9b13fd5dfda140bf58"; # v0.0.4
      hash = "sha256-CtE/2bjnSjeLjbQK/UZQVndmmqLUyzfOcZZCx505PAw=";
    };
    cargoHash = "sha256-IkB85k7kusPL4WCmwUvB3cJ2mTo8J2OUHmClLYFzGao=";
  };
in
{
  programs.zed-editor = {
    extraPackages = config.dev.go.neededPackages;
    extensions = [
      "golangci-lint"
      "gosum"
      "templ"
    ];
    userSettings = {
      # `binary` is the path to dlv that the shim runs in the terminal — not
      # the adapter. Pin it to the Nix dlv so nothing is resolved off $PATH or
      # auto-installed.
      dap.Delve.binary = "${pkgs.delve}/bin/dlv";
      file_types = {
        Go = [
          "**/*.go.golden"
        ];
      };
      lsp = {
        gopls = {
          initialization_options = {
            gofumpt = true;
          };
        };
        golangci-lint = {
          initialization_options = {
            command = [
              "golangci-lint"
              "run"
              "--output.json.path=stdout"
              "--issues-exit-code=1"
              "--show-stats=false"
            ];
          };
        };
      };
      languages = {
        Go = {
          language_servers = [
            "gopls"
            "golangci-lint"
          ];
          tab_size = 4;
          format_on_save = "on";
          formatter = {
            external = {
              #command = "golangci-lint fmt";
              command = "gofumpt";
            };
          };
        };
      };
    };
  };

  # Place our shim where Zed looks for its downloaded one, so it never fetches.
  home.file.".local/share/zed/debug_adapters/delve-shim-dap/delve-shim-dap_v${delve-shim-dap.version}/delve-shim-dap".source =
    "${delve-shim-dap}/bin/delve-shim-dap";
}
