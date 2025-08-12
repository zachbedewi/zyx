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
      type = lib.types.enum [ "pipewire" "pulseaudio" "coreaudio" ];
      description = "Audio backend to use";
      default = "pipewire";
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

    # Advanced audio features
    jackSupport = lib.mkOption {
      type = lib.types.bool;
      description = "Enable JACK audio system support";
      default = false;
    };

    professionalAudio = lib.mkOption {
      type = lib.types.bool;
      description = "Enable professional audio features and tools";
      default = false;
    };

    deviceRouting = lib.mkOption {
      type = lib.types.bool;
      description = "Enable advanced audio device routing capabilities";
      default = false;
    };

    bluetoothAudio = lib.mkOption {
      type = lib.types.bool;
      description = "Enable Bluetooth audio device support";
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
      {
        assertion = 
          config.services.audio.jackSupport -> 
          (config.services.audio.quality == "high" || config.services.audio.quality == "studio");
        message = "JACK support requires high or studio quality audio";
      }
      {
        assertion = 
          config.services.audio.bluetoothAudio -> 
          (config.device.capabilities.hasBluetooth or false);
        message = "Bluetooth audio requires Bluetooth capability";
      }
    ];

    # Platform-specific backend defaults
    services.audio.backend = lib.mkDefault (
      if config.platform.capabilities.isDarwin then "coreaudio"
      else "pipewire"
    );

    # Set intelligent defaults for advanced features based on quality
    services.audio.jackSupport = lib.mkDefault (
      config.services.audio.quality == "studio"
    );

    services.audio.professionalAudio = lib.mkDefault (
      config.services.audio.quality == "high" || config.services.audio.quality == "studio"
    );

    services.audio.deviceRouting = lib.mkDefault (
      config.services.audio.quality == "high" || config.services.audio.quality == "studio"
    );

    services.audio.bluetoothAudio = lib.mkDefault (
      config.device.capabilities.hasBluetooth or false
    );
  };
}