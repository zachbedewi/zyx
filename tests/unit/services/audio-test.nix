# Audio service tests
{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Module imports
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  audioInterface = ../../../modules/services/audio/interface.nix;
  audioNixos = ../../../modules/services/audio/nixos.nix;
  audioDarwin = ../../../modules/services/audio/darwin.nix;

  # Helper to create audio test config
  mkAudioTest = extraConfig: testUtils.evalConfig ([
    platformDetection
    platformCapabilities 
    audioInterface
    audioNixos
    audioDarwin
  ] ++ lib.optional (extraConfig != {}) extraConfig);

  # Test configurations
  basicLaptopConfig = {
    device = {
      type = "laptop";
      capabilities.hasAudio = true;
    };
  };

  studioConfig = basicLaptopConfig // {
    services.audio = {
      quality = "studio";
      lowLatency = true;
    };
  };

  bluetoothConfig = basicLaptopConfig // {
    device.capabilities.hasBluetooth = true;
    services.audio.bluetoothAudio = true;
  };

  darwinConfig = {
    platform.type = "darwin";
    device = {
      type = "laptop"; 
      capabilities.hasAudio = true;
    };
    homebrew.enable = true;
  };

in {
  name = "audio-service";
  tests = [
    {
      name = "audio-service-defaults-enabled-with-capability";
      expr = (mkAudioTest basicLaptopConfig).config.services.audio.enable;
      expected = true;
    }
    
    {
      name = "audio-service-defaults-pipewire-on-nixos";
      expr = (mkAudioTest basicLaptopConfig).config.services.audio.backend;
      expected = "pipewire";
    }
    
    {
      name = "audio-service-defaults-coreaudio-on-darwin";
      expr = (mkAudioTest darwinConfig).config.services.audio.backend;
      expected = "coreaudio";
    }
    
    {
      name = "studio-quality-enables-jack-support";
      expr = (mkAudioTest studioConfig).config.services.audio.jackSupport;
      expected = true;
    }
    
    {
      name = "studio-quality-enables-professional-audio";
      expr = (mkAudioTest studioConfig).config.services.audio.professionalAudio;
      expected = true;
    }
    
    {
      name = "professional-audio-enables-device-routing";
      expr = (mkAudioTest studioConfig).config.services.audio.deviceRouting;
      expected = true;
    }
    
    {
      name = "bluetooth-audio-respects-capability";
      expr = (mkAudioTest bluetoothConfig).config.services.audio.bluetoothAudio;
      expected = true;
    }
    
    {
      name = "nixos-implementation-reports-correct-backend";
      expr = (mkAudioTest basicLaptopConfig).config.services.audio._implementation.backend;
      expected = "pipewire";
    }
    
    {
      name = "nixos-implementation-reports-professional-audio-for-studio";
      expr = (mkAudioTest studioConfig).config.services.audio._implementation.professionalAudio;
      expected = true;
    }
    
    {
      name = "nixos-implementation-reports-device-routing-for-studio";
      expr = (mkAudioTest studioConfig).config.services.audio._implementation.deviceRouting;
      expected = true;
    }
    
    {
      name = "nixos-implementation-stores-correct-metadata";
      expr = (mkAudioTest basicLaptopConfig).config.services.audio._implementation.platform;
      expected = "nixos";
    }
    
    {
      name = "darwin-implementation-stores-correct-metadata";
      expr = (mkAudioTest darwinConfig).config.services.audio._implementation.platform;
      expected = "darwin";
    }
    
    # Valid configuration tests
    {
      name = "audio-service-respects-explicit-enable-false";
      expr = (testUtils.evalConfig [
        platformDetection
        platformCapabilities
        audioInterface
        (basicLaptopConfig // { services.audio.enable = false; })
      ]).config.services.audio.enable;
      expected = false;
    }
    
    {
      name = "bluetooth-audio-disabled-without-capability";
      expr = (testUtils.evalConfig [
        platformDetection
        platformCapabilities
        audioInterface
        {
          device = {
            type = "laptop";
            capabilities = {
              hasAudio = true;
              hasBluetooth = false;
            };
          };
        }
      ]).config.services.audio.bluetoothAudio;
      expected = false;
    }
    
    {
      name = "jack-support-disabled-for-low-quality";
      expr = (testUtils.evalConfig [
        platformDetection
        platformCapabilities
        audioInterface
        (basicLaptopConfig // {
          services.audio.quality = "low";
        })
      ]).config.services.audio.jackSupport;
      expected = false;
    }
  ];
}