# Audio service abstraction interface
{ lib, config, ... }:

{
  options.services.audio = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable audio services";
      default = config.device.capabilities.hasAudio;
    };

    backend = lib.mkOption {
      type = lib.types.enum [ "pipewire" "pulseaudio" "coreaudio" "auto" ];
      description = "Audio backend to use";
      default = "auto";
    };

    quality = lib.mkOption {
      type = lib.types.enum [ "low" "standard" "high" "studio" ];
      description = "Audio quality preset";
      default = "standard";
    };

    lowLatency = lib.mkOption {
      type = lib.types.bool;
      description = "Enable low-latency audio configuration";
      default = false;
    };

    # Internal options for platform-specific implementations
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific audio implementation";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.audio.enable {
    assertions = [
      {
        assertion = config.device.capabilities.hasAudio;
        message = "Audio service requires audio capability";
      }
      {
        assertion = config.services.audio.backend != null;
        message = "Audio backend must be specified";
      }
    ];

    # Auto-select backend based on platform if set to "auto"
    services.audio.backend = lib.mkDefault (
      if config.services.audio.backend == "auto" then
        if config.platform.capabilities.isDarwin then "coreaudio"
        else if config.platform.capabilities.isLinux then "pipewire"
        else "pulseaudio"
      else config.services.audio.backend
    );
  };
}