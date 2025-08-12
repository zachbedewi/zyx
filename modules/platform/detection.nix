# Platform detection module - automatically detects the current platform
{ lib, pkgs, config, ... }:

{
  options.platform = {
    type = lib.mkOption {
      type = lib.types.enum [ "nixos" "darwin" "droid" ];
      description = "The platform type this configuration is running on";
      default = 
        # Automatic platform detection based on available system attributes
        if pkgs.stdenv.isDarwin then "darwin"
        else if pkgs.stdenv.isLinux then
          # Check for Android/Termux environment
          if builtins.pathExists "/system/build.prop" then "droid"
          else "nixos"
        else "nixos";  # Default fallback
    };

    detected = lib.mkOption {
      type = lib.types.str;
      description = "The automatically detected platform";
      readOnly = true;
      default = config.platform.type;
    };

    capabilities = {
      isLinux = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform is Linux-based";
        readOnly = true;
        default = config.platform.type == "nixos" || config.platform.type == "droid";
      };

      isDarwin = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform is Darwin/macOS";
        readOnly = true;
        default = config.platform.type == "darwin";
      };

      supportsSystemd = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform supports systemd";
        readOnly = true;
        default = config.platform.type == "nixos";
      };

      supportsHomeManager = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform supports Home Manager";
        readOnly = true;
        default = true;  # All platforms support Home Manager
      };

      supportsNixOS = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform supports NixOS modules";
        readOnly = true;
        default = config.platform.type == "nixos";
      };

      supportsDarwin = lib.mkOption {
        type = lib.types.bool;
        description = "Whether this platform supports nix-darwin modules";
        readOnly = true;
        default = config.platform.type == "darwin";
      };
    };
  };

  config = {
    # Platform-specific assertions
    assertions = [
      {
        assertion = config.platform.type != null;
        message = "Platform type must be detected or manually specified";
      }
      {
        assertion = builtins.elem config.platform.type [ "nixos" "darwin" "droid" ];
        message = "Platform type must be one of: nixos, darwin, droid";
      }
    ];

    # Add platform information to system environment for debugging
    environment.systemPackages = lib.optionals config.platform.capabilities.supportsNixOS [
      (pkgs.writeShellScriptBin "show-platform" ''
        echo "Platform: ${config.platform.type}"
        echo "Detected: ${config.platform.detected}"
        echo "Linux: ${lib.boolToString config.platform.capabilities.isLinux}"
        echo "Darwin: ${lib.boolToString config.platform.capabilities.isDarwin}"
        echo "Systemd: ${lib.boolToString config.platform.capabilities.supportsSystemd}"
      '')
    ];
  };
}