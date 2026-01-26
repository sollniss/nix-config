{ config, ... }:
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
            Alias = "goc";
            IconURL = "https://github.com/favicon.ico";
            Method = "GET";
            URLTemplate = "https://github.com/search?q={searchTerms}+language%3AGo&type=code";
            #SuggestURLTemplate = "";
          }
          {
            Name = "GitHub (Nix)";
            Description = "GitHub Nix language files search";
            Alias = "nixc";
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
          # disable link preview on long-click
          "browser.ml.linkPreview.enabled" = false;
          # restore open tabs on startup
          "browser.startup.page" = "3";
          # highlight all search results by default
          "findbar.highlightAll" = true;
          # dev console on the right
          "devtools.toolbox.host" = "right";
          # hide bookmark toolbar
          "browser.toolbars.bookmarks.visibility" = "never";
          # enable auto scroll with middle click
          "general.autoScroll" = true;
          # new tab page
          "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          #"browser.newtabpage.pinned" = [
          #  {
          #    title = "NixOS";
          #    url = "https://nixos.org";
          #  }
          #];
          "browser.download.lastDir" = "${config.home.homeDirectory}/Downloads";
          # vertical sidebar
          "sidebar.revamp" = true;
          "sidebar.verticalTabs" = true;
          # split tabs
          "browser.tabs.splitView.enabled" = true;

          # sync bookmarks, history and open tabs only
          "services.sync.declinedEngines" = "addons,passwords,prefs,addresses,creditcards";
          "services.sync.engine.bookmarks" = true; # default
          "services.sync.engine.history" = true; # default
          "services.sync.engine.tabs" = true; # default
          "services.sync.engine.addons" = false;
          "services.sync.engine.addresses" = false; # default
          "services.sync.engine.passwords" = false;
          "services.sync.engine.prefs" = false;
          "services.sync.engine.prefs.modified" = false;
          "services.sync.engine.creditcards" = false; # default

          # disable first time use flags
          "browser.aboutConfig.showWarning" = false;
          "browser.toolbarbuttons.introduced.sidebar-button" = true;
          "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
          "trailhead.firstrun.didSeeAboutWelcome" = true;
          "browser.download.panel.shown" = true;
          "browser.eme.ui.firstContentShown" = true;
          "browser.engagement.ctrlTab.has-used" = true;
          "browser.engagement.downloads-button.has-used" = true;
          "browser.engagement.library-button.has-used" = true;
          "browser.engagement.sidebar-button.has-used" = true;
          "devtools.everOpened" = true;
          "devtools.inspector.simple-highlighters.message-dismissed" = true;

          # Hardening

          # https://wiki.archlinux.org/title/Firefox/Privacy#Disable/enforce_'Trusted_Recursive_Resolver'
          "network.dns.echconfig.enabled" = true;
          "network.dns.http3_echconfig.enabled" = true;
          "network.trr.mode" = 2;
          "network.trr.uri" = "https://dns.quad9.net/dns-query";

          # Use Punycode in Internationalized Domain Names to eliminate possible spoofing
          "network.IDN_show_punycode" = true;

          "privacy.fingerprintingProtection" = true;
          "privacy.trackingprotection.enabled" = true;
        };
      };
    };
  };

  home.sessionVariables.MOZ_ENABLE_WAYLAND = "1";
}
