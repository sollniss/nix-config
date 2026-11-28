{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Helix-style key bindings for the command line (not in nixpkgs).
  # rnwst's fork: a fish 4 rewrite of sshilovsky/fish-helix that covers far
  # more of helix (x/X, J, mm, r, case, /, Space clipboard, motions over
  # autosuggestions) and fixes fish >= 4.8 printing the shared bindings on
  # every new shell. Upstream is a drop-in fallback: same functions layout.
  fish-helix = pkgs.applyPatches {
    name = "fish-helix";
    src = pkgs.fetchFromGitHub {
      owner = "rnwst";
      repo = "fish-helix";
      rev = "b923103a3f3e70ba41b3f59a394d76ae09ae8802";
      hash = "sha256-IBzj/c0mdjopK2fuJmG/3ot9+uKIUuVD/c/iC+gD+gw=";
    };
    postPatch = ''
      # Its functions call perl, which is not on PATH; fail if any call is
      # left unpatched (e.g. a new invocation form after a bump).
      sed -i -E 's#(^|[[:space:](|])perl -#\1${lib.getExe pkgs.perl} -#g' functions/*.fish
      if grep -nE '(^|[[:space:](|])perl( |$)' functions/*.fish; then
        echo "fish-helix: unpatched perl call" >&2
        exit 1
      fi
    '';
  };
in
{
  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "fish-helix";
        src = fish-helix;
      }
    ];

    interactiveShellInit = ''
      # Disable greeting
      set fish_greeting

      set -g fish_key_bindings fish_helix_key_bindings
      # Cursor per mode, like helix: line in insert, block in normal/select.
      set -g fish_cursor_default block
      set -g fish_cursor_insert line
      set -g fish_cursor_visual block
    '';

    functions = {
      # Alt+E edits the command line in the terminal editor ($EDITOR), Alt+V in
      # the graphical one ($VISUAL, falling back to $EDITOR where unset).
      # Defined here so the bindings survive switching vi/emacs key bindings.
      fish_user_key_bindings = {
        body = ''
          for mode in default insert visual
              bind -M $mode alt-e 'VISUAL=$EDITOR edit_command_buffer'
              bind -M $mode alt-v edit_command_buffer
          end
        '';
      };
      where = {
        argumentNames = [ "cmd" ];
        body = ''
          readlink -f (which $cmd)
        '';
      };
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
      #nixosbtw = "nix-shell -p fastfetch --run fastfetch";
      nixosbtw = "nix run nixpkgs#fastfetch";
      sys = ''
        nix-shell -p "inxi.override { withRecommends = true; }" \
          --run "inxi -F"
      '';
    };
  };

  programs.wezterm.extraConfig = ''
    config.default_prog = { '${lib.getExe config.programs.fish.package}', '-i' }
  '';

  programs.zed-editor.userSettings.terminal.shell = {
    with_arguments = {
      program = lib.getExe config.programs.fish.package;
      args = [ "-i" ];
    };
  };
}
