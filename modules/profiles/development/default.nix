{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.profiles.development;
in
{
  options.zyx.profiles.development = {
    enable = mkEnableOption "Enable development profile.";
  };

  config = mkIf cfg.enable {
    zyx = {
      roles = {
        common.enable = true;
      };
    };
  };
}
