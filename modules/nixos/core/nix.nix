{ ... }:
{
  nix.settings = {
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
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?
}
