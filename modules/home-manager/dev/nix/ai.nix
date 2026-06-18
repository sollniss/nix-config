{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.mcp = {
    servers.mcp-nixos = {
      command = lib.getExe pkgs.mcp-nixos;
    };
  };

  programs.claude-code = {
    lspServers.nix = {
      command = lib.getExe pkgs.nixd;
      extensionToLanguage = {
        ".nix" = "nix";
      };
    };
  };
}
