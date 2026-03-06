{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.services.display.greetd;
in
{
  options.zyx.services.display.greetd = {
    enable = mkEnableOption "greetd display manager with tuigreet";
  };

  config = mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session";
          user = "greeter";
        };
      };
    };

    # Unlock the greeter user's keyring on login
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
