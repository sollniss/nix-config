{config, ...}: {
  programs.zed-editor = {
    extraPackages = config.dev.go.neededPackages;
    extensions = ["golangci-lint" "gosum"];
    userSettings = {
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
          language_servers = ["gopls" "golangci-lint"];
          tab_size = 4;
          format_on_save = "on";
          formatter = {
            external = {
              command = "gofumpt";
            };
          };
        };
      };
    };
  };
}
