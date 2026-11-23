{ ... }:
{
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;

      settings = {
        "mailnews.default_sort_type" = 18;
        "mailnews.default_sort_order" = 2;
        "mailnews.default_news_sort_order" = 2;
        "mailnews.default_news_sort_type" = 18;
      };
    };
  };

  xdg.mimeApps.defaultApplications = {
    "x-scheme-handler/mailto" = "thunderbird.desktop";
    "x-scheme-handler/mid" = "thunderbird.desktop";
    "x-scheme-handler/net.thunderbird" = "thunderbird.desktop";
    "message/rfc822" = "thunderbird.desktop";
  };
}
