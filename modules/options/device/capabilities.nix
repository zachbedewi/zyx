{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) bool;
  inherit (lib) mkDefault;
in
{
  options.modules.device = {
    hasAudio = mkOption {
      type = bool;
      default = true;
      description = "True if the device has support for audio. False otherwise.";
    };

    hasGUI = mkOption {
      type = bool;
      default = true;
      description = "True if the device supports graphical user interfaces. False for headless systems.";
    };

    hasGPU = mkOption {
      type = bool;
      default = true; # Conservative default - most modern systems have some GPU
      description = "True if the device has a dedicated or integrated GPU for graphics acceleration.";
    };

    hasWayland = mkOption {
      type = bool;
      default = pkgs.stdenv.isLinux && config.modules.device.hasGPU;
      description = "True if the device supports Wayland display protocol. Requires GPU and Linux.";
    };

    supportsCompositing = mkOption {
      type = bool;
      default = config.modules.device.hasGPU && config.modules.device.hasGUI;
      description = "True if the device supports window compositing effects and hardware acceleration.";
    };
  };

  config = {
    # Capability dependency validation
    assertions = [
      {
        assertion = !config.modules.device.hasWayland || config.modules.device.hasGUI;
        message = "Wayland support requires GUI capability to be enabled.";
      }
      {
        assertion = !config.modules.device.hasWayland || config.modules.device.hasGPU;
        message = "Wayland support requires GPU capability to be enabled.";
      }
      {
        assertion = !config.modules.device.supportsCompositing || config.modules.device.hasGPU;
        message = "Compositing support requires GPU capability to be enabled.";
      }
      {
        assertion = !config.modules.device.supportsCompositing || config.modules.device.hasGUI;
        message = "Compositing support requires GUI capability to be enabled.";
      }
    ];
  };
}
