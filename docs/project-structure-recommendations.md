# Recommendations for Improving Project Structure and Extensibility

This document outlines recommendations for improving the organization and structure of the Nix configuration to make it more extensible for non-NixOS machines through nix-darwin or nix-on-droid.

## 1. Standardize Platform-Agnostic Modules

**Current state:** Modules are primarily organized around NixOS with some darwin support.

**Recommendation:**
- Create a `modules/common` directory for truly platform-agnostic configurations
- Move platform-independent configurations (like shell configurations, editor settings) to this directory
- Use conditional imports based on the platform

```nix
# Example structure
modules/
├── common/           # Platform-agnostic modules
│   ├── shell/
│   ├── editors/
│   └── packages/
├── nixos/            # NixOS-specific modules
├── darwin/           # macOS-specific modules
└── droid/            # Android-specific modules
```

## 2. Implement Feature Flags for Platform Capabilities

**Current state:** You have a good start with `modules/options/device/capabilities.nix`.

**Recommendation:**
- Expand the capabilities system to include platform-specific features
- Create a unified capability detection system that works across platforms

```nix
# Example in modules/options/device/platform.nix
{lib, ...}: {
  options.modules.platform = {
    type = lib.mkOption {
      type = lib.types.enum [ "nixos" "darwin" "droid" ];
      description = "The platform type this configuration is running on";
    };
    
    capabilities = {
      hasGUI = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether the platform supports GUI applications";
      };
      
      # More platform-agnostic capabilities
    };
  };
}
```

## 3. Reorganize Host Configurations

**Current state:** Hosts are organized by platform (nixos, darwin).

**Recommendation:**
- Create a more consistent structure across platforms
- Use a common pattern for all host configurations

```nix
hosts/
├── common/           # Common host configurations
│   └── default.nix   # Imports all platform modules based on detected platform
├── machines/         # Individual machine configurations
│   ├── eye-of-god/   # Your existing NixOS machine
│   ├── macbook-pro/  # Example macOS machine
│   └── pixel/        # Example Android device
└── default.nix       # Main entry point that detects platform and imports appropriate modules
```

## 4. Implement Platform Detection

**Current state:** Platform-specific code is separated but not automatically detected.

**Recommendation:**
- Create a platform detection module that sets appropriate options
- Use this detection to conditionally import platform-specific modules

```nix
# modules/platform-detection.nix
{lib, pkgs, ...}: {
  config = {
    modules.platform.type = 
      if pkgs.stdenv.isDarwin then "darwin"
      else if builtins.pathExists "/system/bin/android" then "droid"
      else "nixos";
  };
}
```

## 5. Refactor Home Manager Configuration

**Current state:** Home manager configuration is somewhat tied to NixOS.

**Recommendation:**
- Create platform-agnostic home-manager configurations
- Use conditional activation based on platform

```nix
# home/default.nix
{config, lib, pkgs, ...}: {
  imports = [
    ./common
    ./programs
  ] ++ lib.optional (config.modules.platform.type == "nixos") ./nixos
    ++ lib.optional (config.modules.platform.type == "darwin") ./darwin
    ++ lib.optional (config.modules.platform.type == "droid") ./droid;
    
  # Platform-specific home directory setting
  home.homeDirectory = 
    if config.modules.platform.type == "darwin" then "/Users/${config.home.username}"
    else if config.modules.platform.type == "droid" then "/data/data/com.termux/files/home"
    else "/home/${config.home.username}";
}
```

## 6. Create Abstraction Layers for System Services

**Current state:** Service configurations are mostly NixOS-specific.

**Recommendation:**
- Create abstraction layers for common services that work across platforms
- Implement platform-specific service configurations behind a common interface

```nix
# modules/services/audio/default.nix
{config, lib, ...}: {
  imports = [
    (./. + "/${config.modules.platform.type}.nix")
  ];
  
  options.modules.services.audio = {
    enable = lib.mkEnableOption "Audio service";
    # Common options across platforms
  };
}

# modules/services/audio/nixos.nix - NixOS implementation
# modules/services/audio/darwin.nix - macOS implementation
# modules/services/audio/droid.nix - Android implementation
```

## 7. Improve Flake Structure for Multi-Platform Support

**Current state:** Your flake.nix is focused on NixOS.

**Recommendation:**
- Update the flake to explicitly support multiple platforms
- Add conditional outputs based on the target system

```nix
{
  description = "Zach's Nix configuration monorepo";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
      imports = [./hosts];
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Your existing inputs
    stylix.url = "github:danth/stylix/release-24.11";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
  };
}
```

## 8. Create a Unified Package Selection System

**Current state:** Package selections are somewhat platform-specific.

**Recommendation:**
- Create a unified package selection system that works across platforms
- Use conditional package selection based on availability

```nix
# modules/packages/default.nix
{config, lib, pkgs, ...}: {
  config = {
    # Common packages available on all platforms
    environment.systemPackages = with pkgs; [
      git
      curl
      wget
    ] 
    # Platform-specific packages
    ++ lib.optionals (config.modules.platform.type == "nixos") [
      firefox
      libreoffice
    ]
    ++ lib.optionals (config.modules.platform.type == "darwin") [
      iterm2
      rectangle
    ]
    ++ lib.optionals (config.modules.platform.type == "droid") [
      termux-api
    ];
  };
}
```

## 9. Implement Consistent XDG Configuration

**Current state:** You have XDG configuration in modules/home/xdg.

**Recommendation:**
- Ensure XDG configuration works consistently across platforms
- Handle platform-specific XDG directories

```nix
# modules/home/xdg/default.nix
{config, lib, ...}: {
  config = {
    xdg = {
      enable = true;
      
      # Platform-specific data home
      dataHome = 
        if config.modules.platform.type == "darwin" then "${config.home.homeDirectory}/Library/Application Support"
        else if config.modules.platform.type == "droid" then "${config.home.homeDirectory}/.local/share"
        else "${config.home.homeDirectory}/.local/share";
        
      # Similar for other XDG directories
    };
  };
}
```

## 10. Create Documentation for Cross-Platform Usage

**Recommendation:**
- Create a README.md with clear instructions for each platform
- Document the extension points for adding new platforms
- Include examples of how to add new machines for each platform

```markdown
# Zach's Nix Configuration

A cross-platform Nix configuration supporting:
- NixOS (Linux)
- nix-darwin (macOS)
- nix-on-droid (Android)

## Setup Instructions

### For NixOS
...

### For macOS
...

### For Android
...

## Adding a New Machine

1. Create a new directory under `hosts/machines/your-machine-name`
2. Copy the template for your platform from `hosts/templates/`
3. Customize as needed
...
```

## 11. Implement Testing for Cross-Platform Compatibility

**Recommendation:**
- Add basic tests to ensure configurations work across platforms
- Create a CI workflow that tests builds for each platform

```nix
# tests/default.nix
{
  nixosTests = {
    basic = import ./nixos/basic.nix;
  };
  
  darwinTests = {
    basic = import ./darwin/basic.nix;
  };
  
  droidTests = {
    basic = import ./droid/basic.nix;
  };
}
```

## 12. Reduce Nesting Depth in Module Structure

**Current state:** Some modules are deeply nested (e.g., `modules/home/packages/terminal/tools/bat/default.nix`).

**Recommendation:**
- Flatten the directory structure where appropriate
- Use more descriptive file names instead of deep nesting

```nix
# Instead of:
modules/home/packages/terminal/tools/bat/default.nix

# Consider:
modules/home/tools/bat.nix
```

## Implementation Strategy

To implement these recommendations effectively:

1. **Start with Platform Detection**: Implement the platform detection module first as it's the foundation for cross-platform support.

2. **Create Common Modules**: Move platform-agnostic configurations to the common directory.

3. **Implement Platform Abstractions**: Create abstraction layers for system services one by one.

4. **Update Flake Structure**: Modify the flake.nix to support multiple platforms.

5. **Reorganize Host Configurations**: Restructure the hosts directory to use the new common pattern.

6. **Document Changes**: Update documentation as you make changes to help future maintenance.

7. **Test Incrementally**: Test each platform as you implement changes to ensure compatibility.
