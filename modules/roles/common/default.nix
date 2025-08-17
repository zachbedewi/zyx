{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.zyx.roles.common;
in {
  options.zyx.roles.common = {
    enable = mkEnableOption "Enable common role.";
  };

  config = mkIf cfg.enable {
    zyx = {
      services = {
        openssh.enable = true;
      };
    };
  };
}
