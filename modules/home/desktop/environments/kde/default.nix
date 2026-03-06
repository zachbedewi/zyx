{
  config,
  lib,
  pkgs,
  desktopConfig,
  ...
}:
let
  session = if desktopConfig != null then desktopConfig.session or null else null;
  isKde = session == "kde";
in
{
  config = lib.mkIf isKde {
    # KDE-specific packages for the user
    home.packages = with pkgs; [
      kdePackages.dolphin # File manager
      kdePackages.konsole # Terminal
      kdePackages.kate # Text editor
      kdePackages.ark # Archive manager
      kdePackages.spectacle # Screenshot tool
      kdePackages.okular # Document viewer
      kdePackages.gwenview # Image viewer
    ];

    # KDE Connect for phone integration
    services.kdeconnect = {
      enable = true;
      indicator = true;
    };
  };
}
