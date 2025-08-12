# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Zyx is a NixOS configuration monorepo that provides centralized configuration management for multiple computing environments. The project uses Nix flakes with flake-parts for modular system configuration.

## Key Development Commands

### Building and Testing
```bash
# Build the current system configuration
sudo nixos-rebuild switch --flake .

# Test configuration without activating
sudo nixos-rebuild test --flake .

# Build specific host (eye-of-god is the current host)
sudo nixos-rebuild switch --flake .#eye-of-god

# Check flake syntax and evaluate all configurations
nix flake check

# Update flake inputs
nix flake update

# Show flake info and outputs
nix flake show

# Build configuration in VM for testing
nixos-rebuild build-vm --flake .
```

### Development Workflow
```bash
# Format Nix code (if formatter is configured)
nix fmt

# Enter development shell with required tools
nix develop

# Evaluate configuration options
nix eval .#nixosConfigurations.eye-of-god.config.system.build.toplevel
```

## Architecture Overview

### Core Structure
- **flake.nix**: Entry point using flake-parts for modular flake definition
- **hosts/**: Host-specific configurations with imports for nixos and darwin
- **modules/**: Modular system components organized by category
- **docs/**: Comprehensive implementation roadmap and documentation

### Module Organization
The project follows a hierarchical module structure:

**modules/options/**: Configuration option definitions
- `device/`: Hardware capabilities (audio, GPU, Wayland support)
- `system/`: System-wide options  
- `user/`: User-specific options

**modules/system/**: Platform-specific system modules
- `nixos/`: NixOS-specific configurations
  - `device/`: Hardware-specific modules (audio servers, display)
  - `environment/`: System environment settings
  - `programs/`: System-level programs (bash, git, zsh)
  - `services/`: System services including display managers
  - `users/`: User account management
- `common/`: Cross-platform modules
- `darwin/`: macOS-specific modules (prepared for future use)

**modules/home/**: Home Manager configurations
- `desktop/wayland/hyprland/`: Wayland compositor configuration
- `packages/`: User package management
- `xdg/`: XDG directory specifications

### Current Host Configuration
- **eye-of-god**: Framework 13" laptop running NixOS
- **Platform**: x86_64-linux with KDE Plasma desktop
- **Features**: Audio (PipeWire), Wayland support, GPU acceleration

### Key Design Principles
1. **Self-contained modules**: Minimize cross-dependencies between modules
2. **Single-level imports**: Avoid deep directory traversal ("../.." patterns)
3. **Capability-driven**: Hardware capabilities determine available features
4. **Platform abstraction**: Prepared for cross-platform support (Darwin, NixOS)

### Current Implementation Status
- ✅ Basic NixOS configuration with KDE Plasma
- ✅ Device capability detection system
- ✅ Audio abstraction with PipeWire support
- ✅ Display service abstraction framework
- 🔄 Hyprland Wayland compositor integration (in progress)
- ⏳ Cross-platform support preparation
- ⏳ Feature flag system implementation

## Important Files
- `hosts/nixos/eye-of-god/default.nix`: Current host configuration
- `modules/options/device/capabilities.nix`: Hardware capability detection
- `modules/system/nixos/services/display/`: Desktop environment abstraction
- `docs/implementation-roadmap.md`: Detailed development roadmap and current work status

## Development Notes

### Module Development
- Follow existing import patterns in module organization
- Use capability detection before enabling hardware-dependent features
- Test configuration changes with `nixos-rebuild test` before switching
- Maintain compatibility with existing eye-of-god configuration during refactoring

### Configuration Testing
- Always test on the eye-of-god configuration before committing changes
- Use VM builds for testing potentially breaking changes
- Verify flake evaluation with `nix flake check`

### Git Workflow
The repository uses conventional commit messages following the existing patterns seen in recent commits. Current branch is `main` which is also the primary development branch.