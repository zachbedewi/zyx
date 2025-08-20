{
  lib,
  config,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.modules.services.display;
in
{
  config = mkIf (cfg.enable && cfg.backend == "x11" && cfg.desktopEnvironment == "plasma") {
    # Enable the KDE Plasma Desktop Environment
    services.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    # Enable automatic login for the primary user
    services.displayManager.autoLogin.enable = true;
    services.displayManager.autoLogin.user = config.modules.user.primaryUser or "skitzo";
  };
}
