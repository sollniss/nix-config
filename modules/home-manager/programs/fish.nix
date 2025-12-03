{
  ...
}:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';
    shellAbbrs = {
      sys = "nix-shell -p fastfetch --run fastfetch";
    };
  };
}