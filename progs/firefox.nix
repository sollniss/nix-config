# https://discourse.nixos.org/t/declare-firefox-extensions-and-settings/36265/7
{ config, pkgs, nur, ... }:

let
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
        #ExtensionSettings = {
        #  # blocks all extensions except the ones specified below.
        #  "*".installation_mode = "blocked";
        #  # uBlock Origin:
        #  "uBlock0@raymondhill.net" = {
        #    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        #    installation_mode = "force_installed";
        #  };
        #  # add extensions here...
        #};

        ExtensionSettings = let
          inherit (pkgs.nur.repos.rycee.firefox-addons) buildFirefoxXpiAddon;
        in [
          (buildFirefoxXpiAddon rec {
            pname = "ublock-origin";
            version = "1.67.0";
						sha256 = "b83c6ec49f817a8d05d288b53dbc7005cceccf82e9490d8683b3120aab3c133a";
						url = "https://addons.mozilla.org/firefox/downloads/file/4598854/ublock_origin-${version}.xpi";
            addonId = "uBlock0@raymondhill.net";
						privateAllowed = true;
						settings = {
							selectedFilterLists = [
								"user-filters"
								"ublock-filters"
								"ublock-badware"
								"ublock-privacy"
								"ublock-unbreak"
								"ublock-quick-fixes"
								"easylist"
								"easyprivacy"
								"urlhaus-1"
								"plowe-0"
							];
						};
						meta = with lib;
						{
							homepage = "https://github.com/gorhill/uBlock#ublock-origin";
							description = "Finally, an efficient wide-spectrum content blocker. Easy on CPU and memory.";
							license = licenses.gpl3;
							mozPermissions = [
								"alarms"
								"dns"
								"menus"
								"privacy"
								"storage"
								"tabs"
								"unlimitedStorage"
								"webNavigation"
								"webRequest"
								"webRequestBlocking"
								"<all_urls>"
								"http://*/*"
								"https://*/*"
								"file://*/*"
								"https://easylist.to/*"
								"https://*.fanboy.co.nz/*"
								"https://filterlists.com/*"
								"https://forums.lanik.us/*"
								"https://github.com/*"
								"https://*.github.io/*"
								"https://github.com/uBlockOrigin/*"
								"https://ublockorigin.github.io/*"
								"https://*.reddit.com/r/uBlockOrigin/*"
							];
							platforms = platforms.all;
						};
          })
        ];


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
      };
    };
  };
}

