{ config, lib, ... }:
{
  config = {
    i18n = {
      defaultLocale = "en_US.UTF-8";
      extraLocaleSettings =
        let
          localeCategories = [
            "LANG"
            "LANGUAGE"
            "LC_ADDRESS"
            "LC_COLLATE"
            "LC_CTYPE"
            "LC_IDENTIFICATION"
            "LC_MEASUREMENT"
            "LC_MESSAGES"
            "LC_MONETARY"
            "LC_NAME"
            "LC_NUMERIC"
            "LC_PAPER"
            "LC_TELEPHONE"
            "LC_TIME"
          ];
        in
        lib.genAttrs localeCategories (_: config.i18n.defaultLocale);
      supportedLocales = [
        "C.UTF-8/UTF-8"
        "en_US.UTF-8/UTF-8"
      ];
    };
  };
}
