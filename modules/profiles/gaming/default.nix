{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.profiles.gaming;
in
{
  options.zyx.profiles.gaming = {
    enable = mkEnableOption "Enable gaming profile.";
  };

  config = mkIf cfg.enable {
    zyx = {
      roles = {
        common.enable = true;
      };
    };
  };
}
