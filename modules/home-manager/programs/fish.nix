{ ... }:
{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set fish_greeting # Disable greeting
    '';

    functions = {
      nixdiff = {
        argumentNames = [ "arg" ];
        body = ''
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
        '';
      };
      "," = {
        body = ''
          if not set -q argv[1]
              echo "Usage: nr <command> [args...]"
              return 1
          end

          set -l cmd $argv[1]

          if test (count $argv) -gt 1
              NIXPKGS_ALLOW_UNFREE=1 nix run --impure "nixpkgs#$cmd" -- $argv[2..-1]
              return
          end

          NIXPKGS_ALLOW_UNFREE=1 nix run --impure "nixpkgs#$cmd"
        '';
      };
      extract = {
        argumentNames = [ "file" ];
        body = ''
          if not test -f "$file"
              echo "'$file' is not a valid file"
              return 1
          end

          switch $file
              case '*.tar.bz2' '*.tbz2'
                  nix run nixpkgs#gnutar -- xjf "$file"
              case '*.tar.gz' '*.tgz'
                  nix run nixpkgs#gnutar -- xzf "$file"
              case '*.bz2'
                  nix run nixpkgs#bzip2 -- -d "$file"
              case '*.rar'
                  NIXPKGS_ALLOW_UNFREE=1 nix run --impure nixpkgs#unrar -- x "$file"
              case '*.gz'
                  nix run nixpkgs#gzip -- -d "$file"
              case '*.tar'
                  nix run nixpkgs#gnutar -- xf "$file"
              case '*.zip'
                  nix run nixpkgs#unzip -- "$file"
              case '*.Z'
                  nix run nixpkgs#ncompress -- -d "$file"
              case '*.7z'
                  nix run nixpkgs#p7zip -- x "$file"
              case '*'
                  echo "Extension not supported."
                  return 1
          end
        '';
      };
    };

    shellAbbrs = {
      #sys = "nix-shell -p fastfetch --run fastfetch";
      sys = "nix run nixpkgs#fastfetch";
    };
  };

  programs.wezterm.extraConfig = ''
    config.default_prog = { 'fish', '-i' }
  '';

  programs.zed-editor.userSettings.terminal.shell = {
    with_arguments = {
      program = "fish";
      args = [ "-i" ];
    };
  };
}
