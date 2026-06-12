{ inputs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Override pkgs.claude-code with the always-latest build from claude-code-nix.
  # Covers every consumer at once: programs.claude-code (devtools.nix) and the
  # CLAUDE_CODE_EXECUTABLE wired into Zed (zed.nix). Applies to home-manager too
  # via useGlobalPkgs.
  nixpkgs.overlays = [
    inputs.claude-code.overlays.default
  ];
}
