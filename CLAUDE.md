# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Zyx is a NixOS configuration monorepo using Nix flakes with flake-parts. It manages system and home configurations for multiple users/hosts from a single repository.

## Commands

```bash
# Build and activate system configuration
sudo nixos-rebuild switch --flake .#eye-of-god

# Test configuration without activating (safe dry run)
sudo nixos-rebuild test --flake .#eye-of-god

# Evaluate flake without building (syntax/type checking)
nix flake check

# Format all Nix files (uses treefmt: nixfmt + deadnix + statix + yamlfmt)
nix fmt

# Update flake inputs
nix flake update

# Build configuration in a VM for testing
nixos-rebuild build-vm --flake .#eye-of-god
```

## Architecture

### Three-Layer Module System

The configuration is organized into three conceptual layers (defined in README.org):

1. **Profiles** (`modules/profiles/`) — *"What can the host do?"* — Hardware/platform capabilities (workstation, server, gaming, development). Enabled per-host via `zyx.profiles.<name>.enable`.

2. **Roles** (`modules/roles/`) — *"What should the host be capable of?"* — Use-case bundles that compose providers. Profiles activate roles.

3. **Providers** (`modules/providers/`) — *"How will features be implemented?"* — Concrete service/program configurations. Split into `common/`, `nixos/`, and (future) `darwin/`.

### Build Pipeline

`flake.nix` → `flake/` (flake-parts modules) → `lib/builder/` → NixOS/Home Manager configurations

Key flow:
- `lib/filesystem/` auto-discovers hosts from `systems/<arch>/<hostname>/` and homes from `homes/<arch>/<user>@<hostname>/`
- `lib/builder/nixos.nix` assembles a NixOS system: loads the host config, all provider/profile/role modules, and builds Home Manager configs for users matched to that hostname
- `lib/builder/common.nix` constructs `specialArgs` passed to all modules (`inputs`, `hostname`, `usernames`, `userDesktops`, etc.)

### Host and Home Configuration

**Systems** live in `systems/<arch>/<hostname>/default.nix`. The current host is `eye-of-god` (Framework 13" laptop).

**Homes** live in `homes/<arch>/<user>@<hostname>/default.nix`. The `@` delimiter maps users to hosts automatically. Each home can have a `desktop.nix` that specifies session type (e.g., `{ session = "kde"; protocol = "wayland"; }`), which gets passed as `desktopConfig` to home modules.

Home modules live in `modules/home/` (desktop, packages, xdg). Home configurations import these directly.

### Special Args Available in Modules

- **System modules**: `inputs`, `self`, `hostname`, `usernames`, `userDesktops`, `lib` (extended)
- **Home modules**: `inputs`, `self`, `hostname`, `username`, `desktopConfig`, `lib` (extended)

### Dev Tooling

Formatting and linting are configured via flake-parts partitions in `flake/dev/`:
- `treefmt` (nixfmt, deadnix, statix, yamlfmt)
- Pre-commit hooks (deadnix, statix, treefmt) if git-hooks-nix is available

### External Inputs

- **home-manager**: User environment management, integrated as NixOS module
- **stylix**: System-wide theming (catppuccin-mocha)
- **sops-nix**: Secrets management
- **zyx-secrets**: Private secrets repo (SSH-authenticated)
- **minimal-emacs**: Emacs configuration (non-flake)

## Conventions

- All Nix files use `nixfmt-rfc-style` formatting
- Module options are namespaced under `zyx.*` (e.g., `zyx.profiles.workstation.enable`)
- Each module directory uses `default.nix` as its entry point
- The `lib/` directory extends nixpkgs lib via an overlay pattern (`lib.overlay`)
