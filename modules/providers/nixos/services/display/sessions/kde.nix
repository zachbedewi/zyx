{
  config,
  lib,
  pkgs,
  userDesktops,
  ...
}:
let
  inherit (lib) mkIf any;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.services.display.sessions.kde;

  # Check if any user wants KDE with X11
  needsX11 = any (d: (d.session or null) == "kde" && (d.protocol or "wayland") == "x11") (
    lib.attrValues userDesktops
  );
in
{
  options.zyx.services.display.sessions.kde = {
    enable = mkEnableOption "KDE Plasma desktop environment session";
  };

  config = mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;

    # Enable X11 if any user needs it for KDE
    services.xserver.enable = needsX11;

    # XDG portal configuration for KDE
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    };
  };
}
