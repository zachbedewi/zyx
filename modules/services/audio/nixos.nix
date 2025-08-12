# NixOS-specific audio service implementation
{ lib, config, pkgs, ... }:

let
  audioConfig = config.services.audio;
  
  # Quality presets for different audio backends
  qualitySettings = {
    pipewire = {
      low = {
        sampleRate = 44100;
        bufferSize = 1024;
      };
      standard = {
        sampleRate = 48000;
        bufferSize = 512;
      };
      high = {
        sampleRate = 96000;
        bufferSize = 256;
      };
      studio = {
        sampleRate = 192000;
        bufferSize = 128;
      };
    };
    pulseaudio = {
      low = {
        sampleRate = 44100;
        fragmentSize = 1024;
      };
      standard = {
        sampleRate = 48000;
        fragmentSize = 512;
      };
      high = {
        sampleRate = 96000;
        fragmentSize = 256;
      };
      studio = {
        sampleRate = 192000;
        fragmentSize = 128;
      };
    };
  };

in {
  config = lib.mkIf (config.services.audio.enable && config.platform.capabilities.supportsNixOS) {
    
    # PipeWire configuration
    services.pipewire = lib.mkIf (audioConfig.backend == "pipewire") {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = audioConfig.quality == "studio";
      
      # Quality-based configuration
      extraConfig.pipewire = {
        "99-zyx-audio" = {
          context.properties = {
            default.clock.rate = qualitySettings.pipewire.${audioConfig.quality}.sampleRate;
            default.clock.quantum = qualitySettings.pipewire.${audioConfig.quality}.bufferSize;
            default.clock.min-quantum = lib.mkIf audioConfig.lowLatency 16;
            default.clock.max-quantum = lib.mkIf audioConfig.lowLatency 64;
          };
        };
      };
      
      # Low latency configuration
      extraConfig.pipewire-pulse = lib.mkIf audioConfig.lowLatency {
        "99-zyx-pulse-lowlatency" = {
          pulse.properties = {
            pulse.min.req = "16/48000";
            pulse.default.req = "32/48000";
            pulse.max.req = "64/48000";
            pulse.min.quantum = "16/48000";
            pulse.max.quantum = "64/48000";
          };
        };
      };
    };

    # PulseAudio configuration (fallback)
    hardware.pulseaudio = lib.mkIf (audioConfig.backend == "pulseaudio") {
      enable = true;
      support32Bit = true;
      
      # Quality-based configuration
      daemon.config = {
        default-sample-rate = qualitySettings.pulseaudio.${audioConfig.quality}.sampleRate;
        default-fragment-size-msec = qualitySettings.pulseaudio.${audioConfig.quality}.fragmentSize;
        
        # Low latency settings
        high-priority = lib.mkIf audioConfig.lowLatency true;
        nice-level = lib.mkIf audioConfig.lowLatency (-15);
        realtime-scheduling = lib.mkIf audioConfig.lowLatency true;
        realtime-priority = lib.mkIf audioConfig.lowLatency 5;
      };
    };

    # Ensure audio group exists and add users
    users.groups.audio = {};
    
    # Add audio packages based on quality level
    environment.systemPackages = with pkgs; [
      # Basic audio tools
      alsa-utils
      pavucontrol
    ] ++ lib.optionals (audioConfig.quality == "high" || audioConfig.quality == "studio") [
      # High-quality audio tools
      qjackctl
      carla
    ] ++ lib.optionals (audioConfig.backend == "pipewire") [
      # PipeWire-specific tools
      helvum
      pwvucontrol
    ];

    # ALSA configuration
    sound.enable = true;
    hardware.alsa = {
      enablePersistence = true;
    };

    # Real-time audio configuration for studio quality
    security.rtkit.enable = audioConfig.quality == "studio" || audioConfig.lowLatency;
    
    # Audio group for users
    users.extraGroups.audio = {};

    # Store implementation details for introspection
    services.audio._implementation = {
      platform = "nixos";
      backend = audioConfig.backend;
      pipewireEnabled = config.services.pipewire.enable;
      pulseaudioEnabled = config.hardware.pulseaudio.enable;
      rtkit = config.security.rtkit.enable;
      qualitySettings = qualitySettings.${audioConfig.backend}.${audioConfig.quality};
    };
  };
}