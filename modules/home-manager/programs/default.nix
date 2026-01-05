{
  anki = import ./anki.nix;
  fish = import ./fish.nix;
  firefox = import ./firefox.nix;
  helix = import ./helix.nix;
  keepassxc = import ./keepassxc.nix;
  thunderbird = import ./thunderbird.nix;
  vscode = import ./vscode.nix;
  wezterm = import ./wezterm.nix;
  zed = import ./zed.nix;

  # preset
  shelltools = import ./shelltools.nix;
}
