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
    services = {
      displayManager = {
        sddm.enable = true;
        autoLogin = {
          enable = true;
          user = config.modules.user.primaryUser or "skitzo";
        };
      };
      xserver.desktopManager.plasma5.enable = true;
    };
  };
}
