{
  lib,
  config,
  pkgs,
  ...
}:

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
    # Options https://mozilla.github.io/policy-templates/
    policies = {
      DisableFirefoxScreenshots = false;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DisplayBookmarksToolbar = false;
      GenerativeAI.Enabled = false;
      FirefoxHome = {
        SponsoredTopSites = false;
      };

      PasswordManagerEnabled = false;
      HardwareAcceleration = true;
      TranslateEnabled = false;

      SearchEngines = {
        Remove = [
          "Bing"
          "Amazon.com"
          "DuckDuckGo"
          "eBay"
          "Ecosia"
          "Wikipedia (en)"
          "Perplexity"
        ];
        Add = [
          {
            Name = "YouTube";
            Description = "YouTube Videos";
            Alias = "yt";
            IconURL = "https://www.youtube.com/favicon.ico";
            Method = "GET";
            URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}&search=Search";
            SuggestURLTemplate = "https://suggestqueries.google.com/complete/search?output=firefox&ds=yt&q={searchTerms}";
          }
          {
            Name = "Wadoku";
            Description = "和独辞典";
            Alias = "wa";
            IconURL = "https://www.wadoku.de/favicon.ico";
            Method = "GET";
            URLTemplate = "https://www.wadoku.de/search/{searchTerms}";
            #SuggestURLTemplate = "https://www.wadoku.de/autosuggest/all/?term={searchTerms}";
          }
          {
            Name = "英辞郎";
            Description = "英辞郎 on the Web";
            Alias = "alc";
            IconURL = "https://eow.alc.co.jp/favicon.ico";
            Method = "GET";
            URLTemplate = "https://eow.alc.co.jp/search?q={searchTerms}";
            #SuggestURLTemplate = "";
          }
          {
            Name = "LEO Eng-Ger";
            Description = "LEOs English-German online dictionary";
            Alias = "leo";
            IconURL = "https://dict.leo.org/img/favicons/ende.ico";
            Method = "GET";
            URLTemplate = "https://dict.leo.org/german-english/{searchTerms}";
            SuggestURLTemplate = "https://dict.leo.org/dictQuery/m-query/conf/ende/query.conf/strlist.json?q={searchTerms}&sort=PLa&shortQuery&noDescription&noQueryURLs";
          }
          {
            Name = "NixOS packages";
            Description = "Search NixOS packages";
            Alias = "nixp";
            IconURL = "https://search.nixos.org/favicon.png";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
            #SuggestURLTemplate = "";
          }
          {
            Name = "NixOS options";
            Description = "Search NixOS options";
            Alias = "nixo";
            IconURL = "https://search.nixos.org/favicon.png";
            Method = "GET";
            URLTemplate = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
            #SuggestURLTemplate = "";
          }
          {
            Name = "Home Manager";
            Description = "Home Manager Options Search";
            Alias = "hm";
            IconURL = "https://home-manager-options.extranix.com/images/favicon.png";
            Method = "GET";
            URLTemplate = "https://home-manager-options.extranix.com/?release=master&query={searchTerms}";
            #SuggestURLTemplate = "";
          }
          {
            Name = "GitHub (Go)";
            Description = "GitHub Go code search";
            Alias = "go";
            IconURL = "https://github.com/favicon.ico";
            Method = "GET";
            URLTemplate = "https://github.com/search?q={searchTerms}+language%3AGo&type=code";
            #SuggestURLTemplate = "";
          }
          {
            Name = "GitHub (Nix)";
            Description = "GitHub Nix language files search";
            Alias = "nix";
            IconURL = "https://github.com/favicon.ico";
            Method = "GET";
            URLTemplate = "https://github.com/search?q={searchTerms}+language%3ANix&type=code";
            #SuggestURLTemplate = "";
          }
        ];
      };

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
        # SponsorBlock for YouTube
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
          updates_disabled = "false";
          private_browsing = "true";
        };
        # Decentraleyes
        "jid1-BoFifL9Vbdl2zQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi";
          installation_mode = "force_installed";
          updates_disabled = "false";
          private_browsing = "true";
        };
      };

      "3rdparty".Extensions = {
        "uBlock0@raymondhill.net".adminSettings = {
          selectedFilterLists = [
            "user-filters"
            "DEU-0"
            "JPN-1"

            # Built-in
            "ublock-filters"
            "ublock-badware"
            "ublock-privacy"
            "ublock-abuse"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "ublock-badlists"

            # Ads
            "easylist"
            "adguard-generic"
            "adguard-mobile"

            # Privacy
            "easyprivacy"
            "adguard-spyware"
            "adguard-spyware-url"
            "block-lan"

            # Multipurpose
            "plowe-0"
            "dpollock-0"

            # Cookie notices
            "fanboy-cookiemonster"
            "ublock-cookies-easylist"
            "adguard-cookies"
            "ublock-cookies-adguard"

            # Social widgets
            "fanboy-social"
            "adguard-social"
            "fanboy-thirdparty_social"

            # Annoyances
            "easylist-chat"
            "easylist-newsletters"
            "easylist-notifications"
            "easylist-annoyances"
            "adguard-mobile-app-banners"
            "adguard-other-annoyances"
            "adguard-popup-overlays"
            "adguard-widgets"
            "ublock-annoyances"

            # URL Shortener tools (replaces clearurls)
            "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/LegitimateURLShortener.txt"

          ];
        };
      };

      # ---- PREFERENCES ----
      # Set preferences shared by all profiles.
      Preferences = {
        "browser.contentblocking.category" = {
          Value = "strict";
          Status = "locked";
        };
        #"extensions.pocket.enabled" = lock-false;
        #"extensions.screenshots.disabled" = lock-true;
        # add global preferences here...
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
          # highlight all search results by default
          "findbar.highlightAll" = true;
          # enable auto scroll
          "general.autoScroll" = true;
          # new tab page
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.pinned" = [
            {
              title = "NixOS";
              url = "https://nixos.org";
            }
          ];
          # activate vertical sidebar
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;

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
