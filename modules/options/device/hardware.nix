{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) enum;
in {
  options.modules.device = {
    type = mkOption {
      type = enum ["laptop" "desktop" "server" "vm"];
      default = "";
      description = ''
        The type of device that this configuration will be deployed on.
      '';
    };
  };

  config.assertions = [
    {
      assertion = config.modules.device.type != null;
      message = ''
        Missing device type. Please define it in the appropriate host configuration.
      '';
    }
  ];
}
