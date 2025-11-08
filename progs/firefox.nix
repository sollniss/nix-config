# https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7
{ lib, config, pkgs, ... }:

let
  buildFirefoxXpiAddon = lib.makeOverridable (
    {
      stdenv ? pkgs.stdenv,
      fetchurl ? pkgs.fetchurl,
      pname,
      version,
      addonId,
      url ? "",
      urls ? [ ], # Alternative for 'url' a list of URLs to try in specified order.
      sha256,
      meta,
      ...
    }:
    stdenv.mkDerivation {
      name = "${pname}-${version}";

      inherit meta;

      src = fetchurl { inherit url urls sha256; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = {
        inherit addonId;
      };

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    }
  );

  lock-false = {
    Value = false;
    Status = "locked";
  };
  lock-true = {
    Value = true;
    Status = "locked";
  };
in
{
  programs.firefox = {
    enable = true;
    package = pkgs.wrapFirefox pkgs.firefox-unwrapped {
      extraPolicies = {
        DisableTelemetry = true;
        # add policies here...

        # ---- EXTENSIONS ----
        ExtensionSettings = {
          # blocks all extensions except the ones specified below.
          "*".installation_mode = "blocked";
          # uBlock Origin:
          "uBlock0@raymondhill.net" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
            installation_mode = "force_installed";
            updates_disabled = "false";
            private_browsing = "true";
          };
          # add extensions here...
        };


        # ---- PREFERENCES ----
        # Set preferences shared by all profiles.
        Preferences = {
          "browser.contentblocking.category" = {
            Value = "strict";
            Status = "locked";
          };
          "extensions.pocket.enabled" = lock-false;
          "extensions.screenshots.disabled" = lock-true;
          # add global preferences here...
        };
      };
    };

    # ---- PROFILES ----
    # Switch profiles via about:profiles page.
    # For options that are available in Home-Manager see
    # https://nix-community.github.io/home-manager/options.html#opt-programs.firefox.profiles
    profiles = {
      # choose a profile name;
      # directory is /home/<user>/.mozilla/firefox/profile_0
      profile_0 = {
        # 0 is the default profile; see also option "isDefault"
        id = 0;
        # name as listed in about:profiles
        name = "profile_0";
        # can be omitted; true if profile ID is 0
        isDefault = true;
        # specify profile-specific preferences here;
        # check about:config for options
        settings = {
          # restore open tabs on startup
          "browser.startup.page" = "3";
          # new tab page
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.pinned" = [
            {
              title = "NixOS";
              url = "https://nixos.org";
            }
          ];
          # activate vertical sidebar
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          # disable translation popup
          "browser.translations.automaticallyPopup" = false;
          # disable first time use flags
          "browser.aboutConfig.showWarning" = false;
          "browser.engagement.sidebar-button.has-used" = true;
          "browser.toolbarbuttons.introduced.sidebar-button" = true;
          "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
          "trailhead.firstrun.didSeeAboutWelcome" = true;
        };

        #extensions."uBlock@raymondhill.net".settings = {
        #  selectedFilterLists = [
        #    "user-filters"
        #  ];
        #};

      };
    };
  };
}

