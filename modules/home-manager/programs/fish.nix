{
  ...
}:
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting


      function nixdiff --argument arg
          if test -z "$arg"
              set arg 0
          else if [ "$arg" = "-a" ]
              nix profile diff-closures --profile /nix/var/nix/profiles/system
              return 0
          end
          
          set tail_n_val (math $arg - 2)

          set versions (command ls -dv /nix/var/nix/profiles/system-*-link | tail $tail_n_val | head -2)
          echo $versions
          nix store diff-closures $versions
      end
    '';
    shellAbbrs = {
      sys = "nix-shell -p fastfetch --run fastfetch";
    };
  };
}