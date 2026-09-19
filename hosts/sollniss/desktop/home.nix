{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  homeManagerModules = with inputs.self.modules.homeManager; [
    base
    theme

    desktops.cosmic

    services.syncthing

    programs.anki
    programs.firefox
    programs.keepassxc
    programs.thunderbird
    #programs.vscode
    programs.zed
    programs.wezterm
    programs.ssh

    # shell
    programs.shelltools
    programs.fish
    programs.helix

    programs.devtools
    dev.go
    dev.nix
  ];
  # untracked and gitignored.
  # builtins.pathExists on an absolute path returns false in pure mode.
  secretModule = /home/sollniss/nix-config/hosts/sollniss/desktop/secret.nix;
in
{
  imports =
    homeManagerModules
    ++ [
      #../../../modules/home-manager/programs/something
    ]
    ++ lib.optional (builtins.pathExists secretModule) (import secretModule);

  home.stateVersion = "25.05";

  prefs.secrets = {
    ankiSollniss = "${config.home.homeDirectory}/.anki-logins/sollniss.txt";
    ankiMzh = "${config.home.homeDirectory}/.anki-logins/mzh.txt";
    # mkdir -m 0700 ~/.syncthing-keys
    # tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 | install -m 0600 /dev/stdin ~/.syncthing-keys/keepass
    # tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32 | install -m 0600 /dev/stdin ~/.syncthing-keys/memos
    syncthingKeepass = "${config.home.homeDirectory}/.syncthing-keys/keepass";
    syncthingMemos = "${config.home.homeDirectory}/.syncthing-keys/memos";
  };

  # SSH public keys.
  home.file = {
    ".ssh/github.pub".text =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHnxLOVT5SkxM5LmQ26ZOfQVyttI0K++U0DD1BzLnsV2\n";
    ".ssh/infra.pub".text = "${config.prefs.network.hosts.nixos.userPubKey}\n";
  };

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "zeditor";

    KOOHA_EXPERIMENTAL = "window-recording";
  };

  # Extra packages.
  home.packages = with pkgs; [
    inkscape
    kooha

    picard
    whipper
    spek

    digikam
    czkawka

    #google-chrome

    # minecraft
    prismlauncher
  ];

  #programs.lutris = {
  #  enable = true;
  #  extraPackages = with pkgs; [
  #    gamemode
  #    mangohud
  #    umu-launcher
  #    winetricks
  #  ];
  #};

  # User specific config for base services.
  services = {
    flameshot = {
      enable = true;
      settings = {
        General = {
          useGrimAdapter = false;
        };
      };
    };

    syncthing.settings =
      let
        network = config.prefs.network;
        self = "nixos";
        peers = lib.filterAttrs (name: host: name != self && host.syncthingId != null) network.hosts;
        folderKeys = {
          keepass = config.prefs.secrets.syncthingKeepass;
          memos = config.prefs.secrets.syncthingMemos;
        };
        folder =
          name:
          let
            f = config.prefs.sync.folders.${name};
          in
          {
            id = f.id;
            type = if lib.elem self f.receiveOnly then "receiveonly" else "sendreceive";
            devices = map (
              h:
              if lib.elem h f.untrusted then
                {
                  name = h;
                  encryptionPasswordFile = folderKeys.${name};
                }
              else
                h
            ) (builtins.filter (h: h != self && network.hosts.${h}.syncthingId != null) f.hosts);
          };
      in
      {
        devices = lib.mapAttrs (name: host: {
          id = host.syncthingId;
          # Global discovery and relays are off, so peers with a fixed LAN
          # address get dialed statically. The phone roams and stays
          # "dynamic" (local announcements find it on the LAN, and over the
          # VPN it dials us).
          addresses =
            if host.subnet == "lan" then
              [ "tcp://${host.ip}:${toString config.prefs.sync.port}" ]
            else
              [ "dynamic" ];
        }) peers;
        folders = {
          "${config.home.homeDirectory}/sync/keepass" = folder "keepass";
          "${config.home.homeDirectory}/sync/photos" = folder "photos";
          "${config.home.homeDirectory}/sync/memos" = folder "memos";
          "/backup/photos" = folder "nas-photos";
          "/backup/music" = folder "nas-music";
        };
      };
  };

  # User specific config for base programs.
  programs = {
    anki = {
      profiles.sollniss.sync = {
        username = config.prefs.user.email;
        keyFile = config.prefs.secrets.ankiSollniss;
      };
      profiles.mzh.sync = {
        username = "m.kodama0410@gmail.com";
        keyFile = config.prefs.secrets.ankiMzh;
      };
      profiles.sollniss.default = true;
    };

    firefox.policies.ExtensionSettings = {
      # 10ten
      "{59812185-ea92-4cca-8ab7-cfcacee81281}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/10ten-ja-reader/latest.xpi";
        installation_mode = "force_installed";
        updates_disabled = "false";
        private_browsing = "true";
      };
    };

    git.settings = {
      user = {
        name = config.prefs.user.name;
        email = config.prefs.user.email;
        signingkey = "${config.home.homeDirectory}/.ssh/github.pub";
      };
      gpg.format = "ssh";
      commit.gpgsign = true;
      tag.gpgsign = true;

      http.cookiefile = "~/.gitcookies";
      # Force SSH auth over HTTPS.
      #url."git@github.com:".insteadOf = "https://github.com/";
    };

    jujutsu.settings = {
      user = {
        name = config.prefs.user.name;
        email = config.prefs.user.email;
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "${config.home.homeDirectory}/.ssh/github.pub";
      };
    };

    keepassxc.database = "${config.home.homeDirectory}/sync/keepass/Passwords.kdbx";

    ssh.settings = {
      "github.com" = {
        IdentityFile = "${config.home.homeDirectory}/.ssh/github.pub";
        IdentitiesOnly = true;
      };
      "raspberrypi ${config.prefs.network.hosts.raspberrypi.ip}" = {
        HostName = config.prefs.network.hosts.raspberrypi.ip;
        User = "root";
        IdentityFile = "${config.home.homeDirectory}/.ssh/infra.pub";
        IdentitiesOnly = true;
      };
      "router ${config.prefs.network.subnets.lan.gateway}" = {
        HostName = config.prefs.network.subnets.lan.gateway;
        User = "root";
        IdentityFile = "${config.home.homeDirectory}/.ssh/infra.pub";
        IdentitiesOnly = true;
        ProxyCommand = "none";
      };
    };
  };

  accounts.email.accounts = {
    "${config.prefs.user.email}" = {
      realName = config.prefs.user.name;
      address = config.prefs.user.email;
      userName = config.prefs.user.name;
      primary = true;
      thunderbird = {
        enable = true;
      };

      imap = {
        host = "imap.web.de";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.web.de";
        port = 465;
        authentication = "plain";
        tls = {
          enable = true;
        };
      };
    };
  };
}
