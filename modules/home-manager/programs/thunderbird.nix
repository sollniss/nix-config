{...}: {
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
}
