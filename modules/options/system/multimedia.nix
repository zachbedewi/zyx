{lib, ...}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.types) bool;
in {
  options.modules.system = {
    audio = {
      enable = mkEnableOption "Enable sound related programs, drivers, and services.";
    };
  };
}
