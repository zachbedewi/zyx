# Nix Configuration Structure Improvements

This document outlines structural improvements to enhance module discoverability, extensibility, and developer experience in the Zyx NixOS configuration monorepo.

## Current Architecture Assessment

### Strengths ✅
- **Clear platform separation** with `nixos/`, `darwin/`, and `common/` directories
- **Capability-driven design** using hardware detection in `modules/options/device/capabilities.nix`
- **Good abstraction layers** like the display services system in `modules/system/nixos/services/display/`
- **Consistent import patterns** that avoid deep directory traversal
- **Modular options system** with organized configuration options

### Areas for Improvement 🔧
- Module discovery requires manual exploration of directory structure
- No centralized registry of available modules and their capabilities
- Limited self-documentation within modules
- Feature combinations require manual module selection
- No automated tooling for understanding module dependencies

## Proposed Improvements

### 1. Module Registry System

**Goal**: Centralize module discovery and categorization

**Implementation**: Create `modules/registry.nix` to serve as a module index:

```nix
# modules/registry.nix
{
  categories = {
    audio = {
      description = "Audio system configuration";
      modules = ["pipewire" "pulseaudio"];
      default = "pipewire";
    };
    
    display = {
      description = "Display servers and desktop environments";
      modules = ["plasma" "hyprland" "x11"];
      backends = ["x11" "wayland"];
    };
    
    development = {
      description = "Development tools and environments";
      modules = ["git" "direnv" "bash" "zsh" "neovim"];
      optional = ["github-cli" "docker"];
    };
    
    security = {
      description = "Security and authentication";
      modules = ["sudo" "gpg" "ssh"];
      required = ["sudo"];
    };
  };
  
  # Module dependency graph
  dependencies = {
    hyprland = ["wayland" "gpu-acceleration"];
    pipewire = ["audio-hardware"];
    plasma = ["x11"];
  };
  
  # Platform compatibility matrix
  platforms = {
    nixos = ["all"];
    darwin = ["development" "security"];  # Prepared for future macOS support
  };
}
```

**Benefits**:
- Single source of truth for available modules
- Clear categorization for easier navigation
- Dependency tracking for proper module ordering
- Platform compatibility information

### 2. Self-Documenting Module Headers

**Goal**: Make each module self-describing with embedded metadata

**Implementation**: Standardize module documentation headers:

```nix
# modules/system/nixos/programs/git.nix
{ lib, config, pkgs, ... }:
# ===== MODULE METADATA =====
# Name: Git Version Control
# Category: development
# Platform: nixos, darwin, common
# Dependencies: []
# Conflicts: []
# Options: modules.programs.git.*
# Description: Git configuration with user settings and aliases
# ============================

let
  cfg = config.modules.programs.git;
in {
  # Module implementation...
}
```

**Benefits**:
- Self-contained module documentation
- Easier dependency tracking
- Clear conflict identification
- Searchable metadata for tooling

### 3. Feature-Based Module Collections

**Goal**: Provide high-level feature combinations for common use cases

**Implementation**: Create `modules/features/` directory:

```
modules/features/
├── desktop-minimal.nix      # Basic desktop: display + audio
├── desktop-full.nix         # Full desktop: DE + apps + multimedia
├── development-basic.nix    # Git + shell + editor
├── development-full.nix     # Full dev stack: languages + tools + containers
├── gaming.nix              # Gaming optimizations + Steam + drivers
├── server-base.nix         # Headless server essentials
└── workstation.nix         # Professional workstation setup
```

Example feature module:
```nix
# modules/features/development-full.nix
{ lib, ... }: {
  imports = [
    ../system/nixos/programs/git
    ../system/nixos/programs/direnv
    ../system/nixos/programs/zsh
  ];
  
  modules = {
    programs = {
      git.enable = lib.mkDefault true;
      direnv.enable = lib.mkDefault true;
      zsh.enable = lib.mkDefault true;
    };
  };
}
```

**Benefits**:
- Quick setup for common configurations
- Reduces boilerplate in host configurations
- Provides tested module combinations
- Easier onboarding for new systems

### 4. Improved Module Organization

**Goal**: Standardize module structure for consistency and discoverability

**Implementation**: Reorganize modules with consistent patterns:

```
modules/system/nixos/programs/
├── _registry.nix            # Local program registry
├── git/
│   ├── default.nix         # Main module implementation
│   ├── options.nix         # Option definitions
│   ├── presets.nix         # Common configuration presets
│   └── integrations.nix    # Integration with other modules
├── zsh/
│   ├── default.nix
│   ├── options.nix
│   ├── plugins.nix         # Plugin management
│   └── themes.nix          # Theme configurations
└── direnv/
    ├── default.nix
    └── options.nix
```

**Benefits**:
- Predictable module structure
- Better separation of concerns
- Easier maintenance and extension
- Consistent option organization

### 5. Auto-Discovery and Documentation Generation

**Goal**: Automated tooling for module discovery and documentation

**Implementation**: Create development scripts:

```bash
# scripts/list-modules.sh
#!/usr/bin/env bash
# Generate module inventory from actual file structure
find modules/ -name "default.nix" -o -name "*.nix" | \
  grep -v registry | sort | \
  xargs grep -l "mkEnableOption\|mkOption" | \
  # Parse module metadata and generate inventory
```

```nix
# scripts/generate-docs.nix
# Nix expression to parse module files and generate documentation
{ pkgs }:
pkgs.writeShellScript "generate-module-docs" ''
  # Extract module metadata and generate markdown documentation
  # Include dependency graphs, option listings, and usage examples
''
```

**Benefits**:
- Always up-to-date module documentation
- Automated dependency analysis
- Integration with existing Nix tooling
- Reduces manual documentation maintenance

### 6. Module Template System

**Goal**: Standardized templates for creating new modules

**Implementation**: Create `templates/` directory with module scaffolding:

```
templates/
├── module-nixos-program.nix     # Template for NixOS programs
├── module-home-manager.nix      # Template for Home Manager modules
├── module-service.nix           # Template for system services
└── module-options.nix           # Template for option definitions
```

**Benefits**:
- Consistent module structure
- Faster module development
- Built-in best practices
- Reduced development errors

## Implementation Strategy

### Phase 1: Foundation (Immediate)
1. Create module registry system
2. Implement self-documenting headers in existing modules
3. Create feature-based collections for current use cases

### Phase 2: Tooling (Short-term)
1. Develop auto-discovery scripts
2. Create module templates
3. Implement documentation generation

### Phase 3: Optimization (Long-term)
1. Refactor existing modules to new structure
2. Add integration testing for feature collections
3. Develop advanced dependency resolution

## Migration Path

1. **Non-breaking additions**: Start with registry and feature modules
2. **Gradual refactoring**: Update modules incrementally during normal maintenance
3. **Tooling integration**: Add scripts without changing existing functionality
4. **Host configuration updates**: Migrate to feature-based imports when convenient

## Expected Benefits

- **Faster development**: Reduced time finding and understanding modules
- **Better maintainability**: Clear structure and documentation standards
- **Easier onboarding**: Feature-based configurations for new systems
- **Improved reliability**: Better dependency tracking and conflict detection
- **Enhanced discoverability**: Automated tooling for module exploration

## Compatibility

All proposed changes are designed to:
- Maintain backward compatibility with existing host configurations
- Work with current flake-parts architecture
- Support the existing capability-driven design
- Preserve platform abstraction (NixOS/Darwin)

This structure builds upon the existing solid foundation while addressing the key pain points in module discovery and extension.