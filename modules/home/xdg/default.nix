{
  config,
  pkgs,
  ...
}:
let
  browser = [ "firefox.desktop" ];
  editor = [ "nvim.desktop" ];

  # For an extensive list of associations, see:
  # https://github.com/iggut/GamiNiX/blob/8070528de419703e13b4d234ef39f05966a7fafb/system/desktop/home-main.nix
  associations = {
    # Editor Associations
    "text/plain" = editor;
    "application/x-zerosize" = editor; # empty files
    "application/x-perl" = editor;
    "application/json" = editor;

    # Browser Associations
    "x-scheme-handler/http" = browser;
    "x-scheme-handler/https" = browser;
    "application/x-extension-htm" = browser;
    "application/x-extension-html" = browser;
    "application/x-extension-shtml" = browser;
    "application/xhtml+xml" = browser;
    "application/x-extension-xhtml" = browser;
    "application/x-extension-xht" = browser;
    "application/pdf" = browser;
    "text/html" = browser;
  };
in
{
  xdg = {
    enable = true;
    cacheHome = "${config.home.homeDirectory}/.cache";
    configHome = "${config.home.homeDirectory}/.config";
    dataHome = "${config.home.homeDirectory}/.local/share";
    stateHome = "${config.home.homeDirectory}/.local/state";

    # Enables management of common user directories
    userDirs = {
      enable = pkgs.stdenv.isLinux;
      createDirectories = true;

      download = "${config.home.homeDirectory}/Downloads";
      desktop = "${config.home.homeDirectory}/Desktop";
      documents = "${config.home.homeDirectory}/Documents";
      music = "${config.home.homeDirectory}/Music";
      pictures = "${config.home.homeDirectory}/Pictures";
      videos = "${config.home.homeDirectory}/Videos";

      # Don't want these directories
      publicShare = null;
      templates = null;
    };

    mime.enable = true;
    mimeApps = {
      enable = true;
      defaultApplications = associations;
      associations.added = associations;
    };
  };
}
