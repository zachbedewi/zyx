{lib, ...}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool;
in {
  options.modules.device = {
    hasAudio = mkOption {
      type = bool;
      default = true;
      description = "True if the device has support for audio. False otherwise.";
    };
  };
}
