{lib, ...}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;
in {
  options.modules.device = {
    hasSound = mkOption {
      type = bool;
      default = true;
      description = "True if the device has sound support. False otherwise.";
    };
  };
}
