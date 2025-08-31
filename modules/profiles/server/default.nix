{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.profiles.server;
in
{
  options.zyx.profiles.server = {
    enable = mkEnableOption "Enable server profile.";
  };

  config = mkIf cfg.enable {
    zyx = {
      roles = {
        common.enable = true;
      };
    };
  };
}
