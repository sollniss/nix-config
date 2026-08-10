{ config, ... }:
{
  nix.gc = {
    automatic = !config.programs.nh.clean.enable;
    dates = "weekly";
    options = "--delete-older-than 30d";
    randomizedDelaySec = "45min";
  };

  nix.settings = {
    min-free = 3 * 1024 * 1024 * 1024;
    max-free = 10 * 1024 * 1024 * 1024;

    # makes everything opening super slow on cosmic
    # also, zed doesn't open with it enabled for some reason.
    #auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = false;
    sandbox = true;
    use-xdg-base-directories = true;

    # cache
    substituters = [
      "https://nix-community.cachix.org"
      "https://catppuccin.cachix.org"
      "https://zed.cachix.org"
      "https://claude-code.cachix.org"
      "https://helix.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      "zed.cachix.org-1:/pHQ6dpMsAZk2DiP4WCL0p9YDNKWj2Q5FL20bNmw1cU="
      "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
    ];
  };
}
