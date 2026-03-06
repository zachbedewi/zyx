# Desktop Environment/Window Manager Configuration Plan

## Overview

Implement a user-specific desktop environment and window manager configuration system that:
- Supports full desktop environments (KDE) and window managers (Hyprland) - initial scope
- Supports both X11 and Wayland protocols
- Uses greetd with tuigreet as the display manager
- Defaults to no desktop (for servers) when not configured
- **Desktop preferences live in user's home config directory (user-specific)**

## Initial Implementation Scope
- **Sessions**: Hyprland (Wayland WM) + KDE Plasma (DE with X11/Wayland)
- **Greeter**: tuigreet (TUI-based, lightweight)

## Architecture Design

### Key Challenge
Home modules cannot access `osConfig` in this repository (by design - keeps home configs portable). We need a way to:
1. Let users specify their desktop preference **in their home config directory**
2. Have the system aggregate all user preferences
3. Enable the required sessions at the system level
4. Configure user-level dotfiles/settings in home modules

### Solution: Metadata-Based Home Config Export

Each user's home config directory contains a `desktop.nix` file that exports their preference.
The filesystem library reads this during config generation, and the builder passes it to both
system (for session enablement) and home (for DE/WM configuration).

```
┌─────────────────────────────────────────────────────────────┐
│  User Home Dir (homes/x86_64-linux/skitzo@eye-of-god/)      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  desktop.nix = {                                    │    │
│  │    session = "hyprland";                            │    │
│  │    protocol = "wayland";                            │    │
│  │  };                                                 │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────────┐  ┌──────────────────────────────┐
│  lib/filesystem              │  │  lib/builder/nixos.nix       │
│  - Reads desktop.nix         │  │  - Passes desktopConfig to   │
│  - Adds to home metadata     │  │    home modules              │
└──────────────────────────────┘  │  - Passes userDesktops to    │
                                  │    NixOS system              │
                                  └──────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────────┐  ┌──────────────────────────────┐
│  System Provider             │  │  Home Module                 │
│  (display/)                  │  │  (desktop/)                  │
│  - Reads userDesktops        │  │  - Reads desktopConfig       │
│  - Enables greetd            │  │  - Configures DE/WM          │
│  - Enables required sessions │  │  - Theming, keybindings      │
└──────────────────────────────┘  └──────────────────────────────┘
```

## File Structure

### User Desktop Config (NEW)
```
homes/x86_64-linux/skitzo@eye-of-god/
├── default.nix               # Main home config (existing)
└── desktop.nix               # NEW: Desktop preference export
```

### System-Level (NixOS Providers)
```
modules/providers/nixos/services/display/
├── default.nix               # Imports all, aggregates userDesktops
├── greetd/
│   └── default.nix           # greetd + tuigreet provider
└── sessions/
    ├── default.nix           # Aggregator - enables sessions based on users
    ├── kde.nix               # KDE Plasma (x11 + wayland)
    └── hyprland.nix          # Hyprland (wayland only)
```

### Home-Level (Home Manager Modules)
```
modules/home/desktop/
├── default.nix               # Imports all, routes based on desktopConfig
├── environments/
│   └── kde/
│       └── default.nix       # KDE user settings
└── window-managers/
    └── hyprland/
        └── default.nix       # Hyprland config (hyprland.conf, etc.)
```

## Implementation Details

### 1. User Desktop Config File
**File:** `homes/x86_64-linux/skitzo@eye-of-god/desktop.nix`

Simple attrset (not a module) that exports preferences:
```nix
{
  session = "hyprland";  # or "kde", null for no desktop
  protocol = "wayland";  # or "x11"
}
```

### 2. Filesystem Library Extension
**File:** `lib/filesystem/default.nix`

Extend `genHomeConfigMetadataForSystem` to read desktop.nix:
```nix
genHomeConfigMetadataForSystem = homesPath: system:
  let
    homesForSystemArchitecturePath = homesPath + "/${system}";
    homes = getDirectoryNames homesForSystemArchitecturePath;
  in
  genAttrs homes (
    userHost:
    let
      parsed = parseDelimittedHomeConfigIdentifier userHost "@";
      homePath = homesForSystemArchitecturePath + "/${userHost}";
      desktopPath = homePath + "/desktop.nix";
    in
    {
      inherit system;
      inherit (parsed) hostname username;
      path = homePath;
      desktop =
        if builtins.pathExists desktopPath
        then import desktopPath
        else null;
    }
  );
```

### 3. Builder Modifications
**File:** `lib/builder/nixos.nix`

Pass desktop config to home modules and aggregate for system:
```nix
# Extract desktop configs for all users on this host
userDesktops = builtins.listToAttrs (
  builtins.map (cfg: {
    name = cfg.username;
    value = cfg.desktop;
  }) homeConfigMetadataForHost
);

# Pass to NixOS system
specialArgs = mkSpecialArgsForHost {
  inherit inputs hostname usernames extendedLib userDesktops;
};

# Pass to each home module
buildHomeModule = { path, hostname, username, desktop, ... }: {
  home-manager.users.${username} = {
    _module.args = mkSpecialArgsForHome {
      inherit inputs hostname username extendedLib;
      desktopConfig = desktop;
    };
  };
};
```

**File:** `lib/builder/common.nix`

Add `desktopConfig` and `userDesktops` to special args:
```nix
mkSpecialArgsForHome = { inputs, hostname, username, extendedLib, desktopConfig ? null }: {
  inherit inputs hostname username desktopConfig;
  # ...
};

mkSpecialArgsForHost = { inputs, hostname, usernames, extendedLib, userDesktops ? {} }: {
  inherit inputs hostname usernames userDesktops;
  # ...
};
```

### 4. Display Provider (System Level)
**File:** `modules/providers/nixos/services/display/default.nix`

```nix
{ config, lib, userDesktops, ... }:
let
  # Get list of unique sessions needed
  enabledSessions = lib.unique (
    lib.filter (s: s != null)
    (lib.mapAttrsToList (_: d: d.session or null) userDesktops)
  );
  hasDesktop = enabledSessions != [];
in
{
  imports = [ ./greetd ./sessions ];

  config = lib.mkIf hasDesktop {
    zyx.services.display = {
      greetd.enable = true;
      sessions = lib.genAttrs enabledSessions (_: { enable = true; });
    };
  };
}
```

### 5. Greetd Provider
**File:** `modules/providers/nixos/services/display/greetd/default.nix`

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.zyx.services.display.greetd;
in
{
  options.zyx.services.display.greetd = {
    enable = lib.mkEnableOption "greetd display manager";
  };

  config = lib.mkIf cfg.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --remember-user-session";
          user = "greeter";
        };
      };
    };
  };
}
```

### 6. Session Providers
**File:** `modules/providers/nixos/services/display/sessions/hyprland.nix`

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.zyx.services.display.sessions.hyprland;
in
{
  options.zyx.services.display.sessions.hyprland = {
    enable = lib.mkEnableOption "Hyprland session";
  };

  config = lib.mkIf cfg.enable {
    programs.hyprland.enable = true;
  };
}
```

### 7. Home Desktop Module
**File:** `modules/home/desktop/default.nix`

```nix
{ config, lib, desktopConfig, ... }:
let
  session = desktopConfig.session or null;
in
{
  imports = [
    ./environments/kde
    ./window-managers/hyprland
  ];

  config = lib.mkIf (session != null) {
    # Common desktop packages/config
  };
}
```

## Session Support Matrix

| Session   | Type        | X11 | Wayland |
|-----------|-------------|-----|---------|
| kde       | Environment | ✓   | ✓       |
| hyprland  | WM          | ✗   | ✓       |

(Additional sessions can be added later following the same pattern)

## Implementation Order

### Phase 1: Library & Builder Changes
1. Extend `lib/filesystem/default.nix` to read desktop.nix
2. Modify `lib/builder/common.nix` to add desktopConfig/userDesktops args
3. Modify `lib/builder/nixos.nix` to pass desktop configs

### Phase 2: System Providers
4. Create `modules/providers/nixos/services/display/default.nix`
5. Create `modules/providers/nixos/services/display/greetd/default.nix`
6. Create `modules/providers/nixos/services/display/sessions/default.nix`
7. Create `modules/providers/nixos/services/display/sessions/hyprland.nix`
8. Create `modules/providers/nixos/services/display/sessions/kde.nix`
9. Update `modules/providers/nixos/services/default.nix` to import display

### Phase 3: Home Modules
10. Create `modules/home/desktop/default.nix`
11. Create `modules/home/desktop/window-managers/hyprland/default.nix`
12. Create `modules/home/desktop/environments/kde/default.nix`

### Phase 4: User Configuration & Migration
13. Create `homes/x86_64-linux/skitzo@eye-of-god/desktop.nix`
14. Update `homes/x86_64-linux/skitzo@eye-of-god/default.nix` to import desktop module
15. Update `systems/x86_64-linux/eye-of-god/default.nix` to remove hardcoded display config

## Files to Modify

| File | Change |
|------|--------|
| `lib/filesystem/default.nix` | Add desktop.nix reading to metadata |
| `lib/builder/common.nix` | Add desktopConfig/userDesktops to special args |
| `lib/builder/nixos.nix` | Extract and pass desktop configs |
| `modules/providers/nixos/services/default.nix` | Add display import |
| `systems/x86_64-linux/eye-of-god/default.nix` | Remove SDDM/Plasma config |
| `homes/x86_64-linux/skitzo@eye-of-god/default.nix` | Import desktop module |

## Files to Create

| File | Purpose |
|------|---------|
| `homes/x86_64-linux/skitzo@eye-of-god/desktop.nix` | User's desktop preference |
| `modules/providers/nixos/services/display/default.nix` | Display service aggregator |
| `modules/providers/nixos/services/display/greetd/default.nix` | greetd provider |
| `modules/providers/nixos/services/display/sessions/default.nix` | Session options |
| `modules/providers/nixos/services/display/sessions/hyprland.nix` | Hyprland session |
| `modules/providers/nixos/services/display/sessions/kde.nix` | KDE session |
| `modules/home/desktop/default.nix` | Home desktop router |
| `modules/home/desktop/window-managers/hyprland/default.nix` | Hyprland home config |
| `modules/home/desktop/environments/kde/default.nix` | KDE home config |

## Usage Example

**User desktop config** (`homes/x86_64-linux/skitzo@eye-of-god/desktop.nix`):
```nix
{
  session = "hyprland";
  protocol = "wayland";
}
```

**User home config** (`homes/x86_64-linux/skitzo@eye-of-god/default.nix`):
```nix
{
  imports = [
    ../../../modules/home/desktop  # Auto-configures based on desktopConfig
    # ... other imports
  ];
}
```

The system automatically:
1. Reads the user's desktop.nix preference
2. Enables greetd since at least one user has a desktop
3. Enables the Hyprland session provider
4. Configures the user's home with Hyprland dotfiles
