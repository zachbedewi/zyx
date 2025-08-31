{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.profiles.workstation;
in
{
  options.zyx.profiles.workstation = {
    enable = mkEnableOption "Enable workstation profile.";
  };

  config = mkIf cfg.enable {
    zyx = {
      roles = {
        common.enable = true;
      };
    };
  };
}
