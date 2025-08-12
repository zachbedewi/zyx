# Device capability detection system
{ lib, pkgs, config, ... }:

{
  options.device = {
    type = lib.mkOption {
      type = lib.types.enum [ "laptop" "desktop" "server" "vm" ];
      description = "Device type for capability detection";
      default = "vm";  # Safe default
    };

    capabilities = {
      hasAudio = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has audio capabilities";
        default = config.device.type != "server";
      };

      hasGPU = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has GPU capabilities";
        default = 
          let
            # Simple GPU detection based on device type and platform
            hasDiscreteGPU = config.device.type == "desktop" || config.device.type == "laptop";
            isGraphicalPlatform = config.platform.capabilities.isLinux || config.platform.capabilities.isDarwin;
          in hasDiscreteGPU && isGraphicalPlatform;
      };

      hasGUI = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports graphical user interfaces";
        default = config.device.type != "server";
      };

      hasWayland = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports Wayland compositor";
        default = 
          config.device.capabilities.hasGUI && 
          config.device.capabilities.hasGPU && 
          config.platform.capabilities.isLinux;
      };

      supportsCompositing = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports desktop compositing";
        default = 
          config.device.capabilities.hasGUI && 
          config.device.capabilities.hasGPU;
      };

      hasNetworking = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has networking capabilities";
        default = true;  # Assume all devices have network
      };

      hasBluetooth = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has Bluetooth capabilities";
        default = config.device.type == "laptop";  # Laptops typically have Bluetooth
      };

      hasWiFi = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has WiFi capabilities";
        default = config.device.type == "laptop";  # Laptops typically have WiFi
      };

      isMobile = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is mobile (battery-powered)";
        default = config.device.type == "laptop";
      };

      # Display-specific capabilities
      hasMultiMonitor = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports multiple monitors";
        default = config.device.type == "desktop" || config.device.type == "laptop";
      };

      hasHiDPI = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has high-DPI display capabilities";
        default = config.device.type == "laptop";  # Modern laptops often have HiDPI displays
      };

      hasHighRefreshRate = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports high refresh rate displays";
        default = config.device.type == "desktop";  # Gaming/workstation desktops
      };

      supportsVR = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports VR/AR capabilities";
        default = 
          config.device.type == "desktop" && 
          config.device.capabilities.hasGPU;
      };

      # Security-specific capabilities
      hasEncryption = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports hardware encryption";
        default = true;  # Most modern devices support disk encryption
      };

      hasSecureBoot = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports UEFI Secure Boot";
        default = config.device.type != "vm";  # VMs typically don't have secure boot
      };

      hasTPM = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has a Trusted Platform Module";
        default = 
          config.device.type == "laptop" || 
          config.device.type == "desktop";  # Modern laptops/desktops often have TPM
      };

      hasSELinux = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports SELinux";
        default = 
          config.platform.capabilities.isLinux && 
          config.device.type != "vm";  # VM might not support SELinux properly
      };

      supportsZFS = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports ZFS filesystem";
        default = 
          config.platform.capabilities.isLinux ||
          config.platform.capabilities.isDarwin;  # ZFS available on Linux and macOS
      };

      hasHardwareRNG = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device has hardware random number generation";
        default = config.device.type != "vm";  # Physical devices typically have HWRNG
      };

      supportsContainerization = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports secure containerization";
        default = 
          config.platform.capabilities.isLinux ||
          config.platform.capabilities.isDarwin;
      };
    };

    # Derived capability combinations for convenience
    profiles = {
      isHeadless = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device runs headless (no GUI)";
        readOnly = true;
        default = !config.device.capabilities.hasGUI;
      };

      isWorkstation = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is suitable as a workstation";
        readOnly = true;
        default = 
          config.device.capabilities.hasGUI &&
          config.device.capabilities.hasAudio &&
          config.device.capabilities.hasGPU;
      };

      isDevelopmentMachine = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is suitable for development";
        readOnly = true;
        default = 
          config.device.capabilities.hasGUI &&
          config.device.capabilities.hasNetworking;
      };

      isDevelopment = lib.mkOption {
        type = lib.types.bool;
        description = "Alias for isDevelopmentMachine";
        readOnly = true;
        default = config.device.profiles.isDevelopmentMachine;
      };

      isMediaCenter = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is suitable as a media center";
        readOnly = true;
        default = 
          config.device.capabilities.hasGUI &&
          config.device.capabilities.hasAudio &&
          config.device.capabilities.hasGPU;
      };

      isGaming = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is suitable for gaming";
        readOnly = true;
        default = 
          config.device.capabilities.hasGUI &&
          config.device.capabilities.hasGPU &&
          config.device.capabilities.hasAudio &&
          (config.device.type == "desktop" || config.device.type == "laptop");
      };

      # Security-specific profiles
      isServer = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device is a server requiring high security";
        readOnly = true;
        default = config.device.type == "server";
      };

      requiresHighSecurity = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device requires high security hardening";
        readOnly = true;
        default = 
          config.device.profiles.isServer ||
          config.device.profiles.isWorkstation;
      };

      supportsFullEncryption = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device supports full disk encryption with TPM";
        readOnly = true;
        default = 
          config.device.capabilities.hasEncryption &&
          config.device.capabilities.hasTPM;
      };

      canUseSecureBoot = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this device can utilize secure boot effectively";
        readOnly = true;
        default = 
          config.device.capabilities.hasSecureBoot &&
          config.device.type != "vm";
      };
    };
  };

  config = {
    # Capability dependency assertions
    assertions = [
      {
        assertion = config.device.type != null;
        message = "Device type must be specified";
      }
      {
        assertion = 
          config.device.capabilities.hasWayland -> 
          (config.device.capabilities.hasGUI && config.device.capabilities.hasGPU);
        message = "Wayland requires both GUI and GPU capabilities";
      }
      {
        assertion = 
          config.device.capabilities.supportsCompositing -> 
          config.device.capabilities.hasGUI;
        message = "Desktop compositing requires GUI capability";
      }
      {
        assertion = 
          config.device.capabilities.hasWayland -> 
          config.platform.capabilities.isLinux;
        message = "Wayland is only supported on Linux platforms";
      }
      {
        assertion = 
          config.device.profiles.isWorkstation -> 
          config.device.capabilities.hasGUI;
        message = "Workstation profile requires GUI capability";
      }
    ];

    # Expose capability information for debugging
    environment.systemPackages = lib.optionals config.platform.capabilities.supportsNixOS [
      (pkgs.writeShellScriptBin "show-capabilities" ''
        echo "Device Type: ${config.device.type}"
        echo "Audio: ${lib.boolToString config.device.capabilities.hasAudio}"
        echo "GPU: ${lib.boolToString config.device.capabilities.hasGPU}"
        echo "GUI: ${lib.boolToString config.device.capabilities.hasGUI}"
        echo "Wayland: ${lib.boolToString config.device.capabilities.hasWayland}"
        echo "Compositing: ${lib.boolToString config.device.capabilities.supportsCompositing}"
        echo "Network: ${lib.boolToString config.device.capabilities.hasNetworking}"
        echo "Bluetooth: ${lib.boolToString config.device.capabilities.hasBluetooth}"
        echo "WiFi: ${lib.boolToString config.device.capabilities.hasWiFi}"
        echo "Multi-Monitor: ${lib.boolToString config.device.capabilities.hasMultiMonitor}"
        echo "HiDPI: ${lib.boolToString config.device.capabilities.hasHiDPI}"
        echo "High Refresh: ${lib.boolToString config.device.capabilities.hasHighRefreshRate}"
        echo "VR Support: ${lib.boolToString config.device.capabilities.supportsVR}"
        echo ""
        echo "Security Capabilities:"
        echo "  Encryption: ${lib.boolToString config.device.capabilities.hasEncryption}"
        echo "  Secure Boot: ${lib.boolToString config.device.capabilities.hasSecureBoot}"
        echo "  TPM: ${lib.boolToString config.device.capabilities.hasTPM}"
        echo "  SELinux: ${lib.boolToString config.device.capabilities.hasSELinux}"
        echo "  ZFS: ${lib.boolToString config.device.capabilities.supportsZFS}"
        echo "  Hardware RNG: ${lib.boolToString config.device.capabilities.hasHardwareRNG}"
        echo "  Containerization: ${lib.boolToString config.device.capabilities.supportsContainerization}"
        echo ""
        echo "Profiles:"
        echo "  Headless: ${lib.boolToString config.device.profiles.isHeadless}"
        echo "  Workstation: ${lib.boolToString config.device.profiles.isWorkstation}"
        echo "  Development: ${lib.boolToString config.device.profiles.isDevelopmentMachine}"
        echo "  Media Center: ${lib.boolToString config.device.profiles.isMediaCenter}"
        echo "  Gaming: ${lib.boolToString config.device.profiles.isGaming}"
        echo "  Server: ${lib.boolToString config.device.profiles.isServer}"
        echo "  High Security: ${lib.boolToString config.device.profiles.requiresHighSecurity}"
        echo "  Full Encryption: ${lib.boolToString config.device.profiles.supportsFullEncryption}"
        echo "  Secure Boot Ready: ${lib.boolToString config.device.profiles.canUseSecureBoot}"
      '')
    ];
  };
}