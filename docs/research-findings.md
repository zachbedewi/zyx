# Zyx NixOS Configuration Monorepo - Research Findings

> Generated: 2026-02-15 | Branch: feature/desktop-configuration

## Table of Contents

- [1. Current Codebase Inventory](#1-current-codebase-inventory)
- [2. Architecture Analysis](#2-architecture-analysis)
- [3. Developer Experience Audit](#3-developer-experience-audit)
- [4. Secrets Management Analysis](#4-secrets-management-analysis)
- [5. Flake-Parts Philosophy & Best Practices](#5-flake-parts-philosophy--best-practices)
- [6. Dendritic Configuration Pattern](#6-dendritic-configuration-pattern)
- [7. Remote Deployment Tools](#7-remote-deployment-tools)
- [8. AI-Native Repository Patterns](#8-ai-native-repository-patterns)
- [9. Issues & Gaps Identified](#9-issues--gaps-identified)
- [10. Strengths of Current Design](#10-strengths-of-current-design)

---

## 1. Current Codebase Inventory

### Directory Structure

```
zyx/
├── flake.nix                          # Main flake entry point
├── flake.lock                         # Locked dependencies
├── CLAUDE.md                          # AI assistant project guidance
├── README.org                         # Architecture documentation
├── .mcp.json                          # MCP server configuration (mcp-nixos)
│
├── flake/                             # Flake-parts modules
│   ├── default.nix                    # Main flake-parts config, imports, partitions
│   ├── configurations.nix             # NixOS system config discovery & output
│   ├── homes.nix                      # Home Manager config discovery & output
│   └── dev/                           # Development tooling (partitioned)
│       ├── default.nix                # Imports format, checks, devShells
│       ├── flake.nix                  # Separate dev inputs (treefmt-nix, git-hooks-nix)
│       ├── format.nix                 # treefmt: nixfmt, deadnix, statix, yamlfmt
│       ├── checks.nix                # Pre-commit hooks: deadnix, statix, treefmt
│       └── devShells.nix             # Dev shell: nh, deadnix, statix, sops, formatter
│
├── lib/                               # Core library functions
│   ├── default.nix                    # Exports filesystem, builder, overlay
│   ├── filesystem/
│   │   └── default.nix               # Auto-discovery of hosts/homes, metadata generation
│   ├── builder/
│   │   ├── default.nix               # Exports buildHomeConfiguration, buildNixosSystem
│   │   ├── common.nix                # Shared: mkExtendedLib, mkSpecialArgsForHome/Host
│   │   ├── nixos.nix                 # NixOS system builder (integrates HM as submodule)
│   │   └── home.nix                  # Standalone Home Manager builder
│   └── overlay/
│       └── default.nix               # Extends nixpkgs lib: lib.zyx.*, lib.hm.*
│
├── modules/                           # Three-layer module system
│   ├── profiles/                      # Layer 1: Host capabilities
│   │   ├── default.nix               # Imports all profiles
│   │   ├── workstation/default.nix   # Stub: enables zyx.roles.common
│   │   ├── development/default.nix   # Stub: enables zyx.roles.common
│   │   ├── gaming/default.nix        # Stub: enables zyx.roles.common
│   │   └── server/default.nix        # Stub: enables zyx.roles.common
│   │
│   ├── roles/                         # Layer 2: Use-case bundles
│   │   ├── default.nix               # Imports all roles
│   │   └── common/default.nix        # Enables openssh
│   │
│   ├── providers/                     # Layer 3: Concrete implementations
│   │   ├── common/                    # Cross-platform providers
│   │   │   └── nix/default.nix       # Nix/Lix configuration, GC, optimization, settings
│   │   └── nixos/                     # NixOS-specific providers
│   │       ├── programs/
│   │       │   └── terminal/
│   │       │       ├── bash/default.nix      # Bash + starship
│   │       │       ├── git/default.nix       # Git (minimal)
│   │       │       ├── nano/default.nix      # Nano (minimal)
│   │       │       └── zsh/default.nix       # Zsh (system-level)
│   │       ├── security/
│   │       │   ├── sops/default.nix          # SOPS secrets management
│   │       │   └── sudo/default.nix          # Sudo configuration
│   │       ├── services/
│   │       │   ├── default.nix               # Imports all services
│   │       │   ├── display/                   # Display manager & sessions
│   │       │   │   ├── default.nix           # Aggregates user desktop prefs
│   │       │   │   ├── greetd/default.nix    # tuigreet + greetd
│   │       │   │   └── sessions/
│   │       │   │       ├── default.nix       # Session aggregator
│   │       │   │       ├── kde.nix           # KDE Plasma 6
│   │       │   │       └── hyprland.nix      # Hyprland compositor
│   │       │   ├── openssh/default.nix       # SSH daemon (port 30, hardened)
│   │       │   └── pipewire/
│   │       │       ├── default.nix           # PipeWire audio server
│   │       │       └── settings.nix          # PipeWire tuning
│   │       ├── system/
│   │       │   ├── environment/default.nix   # Env vars, system packages
│   │       │   └── locale/default.nix        # Locale & i18n
│   │       └── user/default.nix              # User account management
│   │
│   └── home/                          # Home Manager modules
│       ├── desktop/
│       │   ├── default.nix                   # Desktop routing by desktopConfig
│       │   ├── environments/kde/default.nix  # KDE user packages + services
│       │   └── window-managers/hyprland/default.nix  # Hyprland config + keybinds
│       ├── packages/
│       │   └── terminal/
│       │       ├── shell/zsh/
│       │       │   ├── default.nix           # Zsh config (history, completion, etc.)
│       │       │   ├── aliases.nix           # Shell aliases (ls→eza, cat→bat)
│       │       │   ├── plugins.nix           # Zsh plugins
│       │       │   └── config/completion.zsh # Zsh completion config
│       │       ├── editors/emacs/default.nix # Emacs (incomplete, mostly commented out)
│       │       ├── emulators/kitty/default.nix # Kitty terminal
│       │       └── tools/
│       │           ├── eza/default.nix       # Modern ls replacement
│       │           ├── bat/default.nix       # Syntax-highlighted cat
│       │           └── zoxide/default.nix    # Smart cd
│       └── xdg/default.nix                  # XDG base dirs + MIME associations
│
├── systems/                           # NixOS host configurations
│   └── x86_64-linux/
│       └── eye-of-god/
│           ├── default.nix           # Host config (Framework 13", profiles, boot, etc.)
│           └── hardware-configuration.nix  # Generated hardware config
│
├── homes/                             # Home Manager user configurations
│   └── x86_64-linux/
│       ├── skitzo@eye-of-god/
│       │   ├── default.nix           # User config (imports modules, HM settings)
│       │   └── desktop.nix           # Desktop preference: { session="kde"; protocol="wayland"; }
│       └── zach@eye-of-god/
│           └── default.nix           # User config (no desktop.nix = no GUI)
│
├── home/                              # Shared home utilities
│   └── starship.nix                  # Starship prompt enablement
│
└── docs/
    └── desktop-configuration-plan.md # Desktop feature implementation plan
```

### File Statistics

- **Total Nix files**: ~72
- **Flake inputs**: 7 (nixpkgs, nixpkgs-unstable, flake-parts, home-manager, sops-nix, stylix, minimal-emacs) + 1 private (zyx-secrets)
- **Hosts configured**: 1 (eye-of-god)
- **Users configured**: 2 (skitzo, zach)
- **Profiles defined**: 4 (workstation, development, gaming, server) — all stubs
- **Roles defined**: 1 (common)
- **Desktop sessions**: 2 (KDE Plasma 6, Hyprland)
- **Platform support**: x86_64-linux only (darwin filtering exists but unused)

### Flake Inputs Detail

| Input | Source | Purpose |
|-------|--------|---------|
| `nixpkgs` | nixos-unstable | Primary package set |
| `nixpkgs-unstable` | nixos-unstable | Standalone HM builds |
| `flake-parts` | github:hercules-ci/flake-parts | Modular flake framework |
| `home-manager` | github:nix-community/home-manager | User environment management |
| `sops-nix` | github:Mic92/sops-nix | Secrets management |
| `zyx-secrets` | git+ssh (private) | Encrypted secrets repo |
| `stylix` | github:danth/stylix | System-wide theming (catppuccin-mocha) |
| `minimal-emacs` | github (non-flake) | Emacs configuration framework |

### Dev Partition Inputs

| Input | Purpose |
|-------|---------|
| `git-hooks-nix` | Pre-commit hook framework |
| `treefmt-nix` | Multi-formatter orchestration |

---

## 2. Architecture Analysis

### Build Pipeline

```
flake.nix
  └── flake/default.nix (flake-parts mkFlake)
        ├── imports ../lib (filesystem, builder, overlay)
        ├── flake/configurations.nix
        │     └── genAllHostConfigMetadata → filterNixosHosts → buildNixosSystem
        │           └── lib/builder/nixos.nix
        │                 ├── mkExtendedLib (lib overlay injection)
        │                 ├── genAllHomeConfigMetadata (discover users for this host)
        │                 ├── mkSpecialArgsForHost (inputs, hostname, usernames, userDesktops)
        │                 ├── Loads: home-manager, stylix, sops-nix NixOS modules
        │                 ├── Loads: profiles, roles, providers/common, providers/nixos
        │                 ├── Loads: host-specific config (systems/<arch>/<hostname>/)
        │                 └── For each user: buildHomeModule
        │                       ├── mkSpecialArgsForHome (inputs, hostname, username, desktopConfig)
        │                       └── Imports user's home dir + modules/home/*
        └── flake/homes.nix
              └── genAllHomeConfigMetadata → buildHomeConfiguration
                    └── lib/builder/home.nix (standalone HM, uses nixpkgs-unstable)
```

### Three-Layer Module Pattern

```
Profile (What can the host do?)     →    Role (What should it do?)    →    Provider (How?)
─────────────────────────────────        ──────────────────────────        ─────────────────
zyx.profiles.workstation.enable          zyx.roles.common.enable          zyx.services.openssh
zyx.profiles.development.enable          (future: zyx.roles.dev)          zyx.services.pipewire
zyx.profiles.gaming.enable               (future: zyx.roles.gaming)       zyx.services.display.*
zyx.profiles.server.enable               (future: zyx.roles.media)        zyx.security.sops
```

**Current reality**: All profiles just enable `zyx.roles.common`, which only enables openssh. The framework exists but is underutilized.

### Special Args Flow

```
System modules receive:
  inputs, self, hostname, usernames, userDesktops, lib (extended)

Home modules receive:
  inputs, self, hostname, username, desktopConfig, lib (extended)
```

### Desktop Configuration Flow

```
homes/<arch>/<user>@<host>/desktop.nix    # User declares: { session = "kde"; protocol = "wayland"; }
    ↓
lib/filesystem/ reads desktop.nix          # Attached to home metadata as `desktop` attribute
    ↓
lib/builder/nixos.nix aggregates           # Collects all users' desktops into userDesktops dict
    ↓
modules/providers/nixos/services/display/  # System enables greetd + required sessions
    ↓
modules/home/desktop/                      # User's HM config routes by desktopConfig.session
```

---

## 3. Developer Experience Audit

### What Exists

| Tool | Status | Location |
|------|--------|----------|
| **Formatter** (nixfmt-rfc-style) | Configured | flake/dev/format.nix |
| **Linter** (statix) | Configured | flake/dev/format.nix |
| **Dead code** (deadnix) | Configured | flake/dev/format.nix |
| **YAML formatter** (yamlfmt) | Configured | flake/dev/format.nix |
| **Pre-commit hooks** | Configured but NOT activated | flake/dev/checks.nix |
| **Dev shell** | Basic | flake/dev/devShells.nix |
| **Language server** (nil) | System package only | systems/eye-of-god/default.nix |
| **MCP server** (mcp-nixos) | Configured | .mcp.json |
| **CLAUDE.md** | Comprehensive | Root directory |

### What's Missing

| Tool/Feature | Impact | Priority |
|-------------|--------|----------|
| **CI/CD pipeline** | No automated validation on commits/PRs | High |
| **NixOS VM tests** | No integration testing | High |
| **nixd** (language server) | More capable than nil, workspace-aware | Medium |
| **direnv integration** | Auto-activate dev shell on cd | Medium |
| **Cachix/binary cache** | Every build from scratch | Medium |
| **nix flake check** in CI | Not automated | High |
| **Module option tests** | No validation of custom options | Medium |
| **Documentation generation** | No auto-generated option docs | Low |
| **Automated flake updates** | Manual `nix flake update` only | Low |

### Dev Shell Contents

```nix
# Current packages in devShell:
nh          # NixOS helper CLI
deadnix     # Dead code detection
statix      # Nix linting
sops        # Secrets CLI
formatter   # nixfmt-rfc-style via treefmt
```

### Pre-commit Hooks (Configured, Not Activated)

```nix
# Available hooks:
deadnix     # Check for dead code
statix      # Lint Nix
treefmt     # Format check
```

Hooks are conditional on `git-hooks-nix` being available. The `.git/hooks/` directory only contains `.sample` files.

---

## 4. Secrets Management Analysis

### Current Setup

- **Tool**: sops-nix (Mozilla SOPS + age encryption)
- **Secrets repo**: `zyx-secrets` (private, SSH-authenticated git repo)
- **Secrets file**: `${zyx-secrets}/sops/secrets.yaml`
- **Encryption**: age keys derived from SSH host keys
- **Key derivation**: `/etc/ssh/ssh_host_ed25519_key` → age key at `/var/lib/sops-nix/key.txt`
- **Auto-generate**: Yes (`sops.age.generateKey = true`)
- **Validation**: Disabled (`validateSopsFiles = false`)

### Configured Secrets

| Secret | Owner | Notes |
|--------|-------|-------|
| `zach-password` | root | User password hash |

### Gaps

- Only 1 secret configured (zach-password). No skitzo-password.
- No `.sops.yaml` creation rules documented for multi-host
- No secret rotation procedures documented
- No per-host secret isolation (single secrets.yaml for all)
- Validation disabled — misconfigurations won't surface at build time
- No integration with deployment tooling
- No documentation on onboarding a new host's age key

### Multi-Host Best Practices (from research)

```yaml
# Recommended .sops.yaml structure for multi-host:
creation_rules:
  - path_regex: secrets/eye-of-god/.*
    key_groups:
      - age:
        - <eye-of-god-host-key>
        - <admin-personal-key>
  - path_regex: secrets/new-host/.*
    key_groups:
      - age:
        - <new-host-key>
        - <admin-personal-key>
```

---

## 5. Flake-Parts Philosophy & Best Practices

### Core Principles

1. **Minimal mirror of flake schema** — flake-parts is deliberately lightweight
2. **Separation of concerns** — each module file = one feature/concern
3. **Baseline compatibility** — standard flake attributes always available
4. **Extensibility** — community modules extend functionality

### Partition System

Partitions allow different flake attributes to evaluate with different input sets. Benefits:
- Dev inputs (treefmt, git-hooks) don't pollute consumer lock files
- CI can evaluate only what's needed
- Faster evaluation by avoiding unnecessary imports

**Zyx status**: Uses partitions for dev tooling (correct pattern).

### Anti-Patterns to Avoid

1. **Extra inputs bloat** — don't import all inputs in every evaluation
2. **Over-nested module files** — keep directory depth reasonable
3. **Mixed responsibilities** — one module = one concern
4. **Implicit dependencies** — use `specialArgs` explicitly, document deps

### What Zyx Does Well

- `configurations.nix` and `homes.nix` are properly separated
- Dev tools are partitioned
- Module files are focused

### What Could Improve

- Profiles/roles could be more granular flake-parts modules
- Could use flake-parts' `perSystem` more for per-system tooling
- Missing explicit partition documentation

---

## 6. Dendritic Configuration Pattern

### What It Is

A Nixpkgs module system usage pattern where **every file is a top-level flake-parts module**. Files can read from and write to the top-level config directly, eliminating specialArgs chains.

### How It Differs from Zyx's Current Approach

| Aspect | Current Zyx | Dendritic |
|--------|-------------|-----------|
| **Value passing** | specialArgs chains (inputs→builder→module) | Top-level config (all files read/write config.*) |
| **File organization** | By type (modules/providers/nixos/services/) | By feature (flake/desktop/{nixos,hm,common}.nix) |
| **Module type** | Mix of NixOS modules, HM modules, lib functions | Everything is a flake-parts module |
| **Cross-config access** | Requires explicit threading via specialArgs | Direct via `config.zyx.*` |
| **Import mechanism** | Manual imports lists | Auto-import by directory convention |

### Migration Effort

- **Significant rewrite** required
- Deep understanding of `deferredModule` type needed
- Reorganize from type-based to feature-based hierarchy
- Eliminate specialArgs chains
- Auto-import system replaces manual imports

### Assessment

- **Not recommended for current scale** (1 host, 2 users)
- **Consider at 5+ hosts** or with very tight cross-config coupling
- Current architecture is pragmatic and maintainable
- Dendritic is still niche with fewer community examples

### Key Resources

- [Dendritic GitHub](https://github.com/mightyiam/dendritic)
- [Dendrix community distribution](http://dendrix.oeiuwq.com/)
- [NixCon 2025 talk](https://talks.nixcon.org/nixcon-2025/talk/REJ3LF/)
- [Discourse discussion](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271)

---

## 7. Remote Deployment Tools

### Comparison

| Feature | deploy-rs | Colmena | nixos-anywhere |
|---------|-----------|---------|----------------|
| **Purpose** | Multi-profile deployment | Parallel multi-host orchestration | Bare metal provisioning |
| **Parallelization** | Per-profile | Full parallel | Single host |
| **Secrets** | External tool required | Built-in sops support | Separate setup |
| **Flake integration** | Native | Via colmenaHive output | Via scripts |
| **Learning curve** | Low | Low-medium | Medium |
| **Best for** | Small deployments | Growing fleet | Initial provisioning |

### Colmena (Recommended for Zyx)

- Parallel deployment across hosts
- Tag-based host selection (`colmena apply --on @workstations`)
- Integrated secrets management
- Thin wrapper over `nix`, predictable behavior
- Simple configuration (flake-based or standalone `hive.nix`)

### nixos-anywhere (Complementary)

- Provisions bare metal or cloud instances without pre-installed NixOS
- Uses kexec to boot into NixOS installer over SSH
- Ideal for initial host bootstrapping
- Can be combined with colmena for ongoing management

### Unified Installation Script Considerations

A unified script would need to handle:
1. **Bootstrap**: Install NixOS on new hardware (nixos-anywhere)
2. **Deploy**: Push configuration updates (colmena/deploy-rs)
3. **Secrets**: Provision age keys, encrypt/decrypt secrets
4. **Rollback**: Revert to previous generation on failure
5. **Multi-arch**: Support x86_64-linux and future architectures

---

## 8. AI-Native Repository Patterns

### Current AI Integration

| Feature | Status |
|---------|--------|
| CLAUDE.md | Comprehensive, well-structured |
| .mcp.json | mcp-nixos configured |
| claude-code | Installed as system package |
| .claude/ | settings.local.json exists |

### Enhancement Opportunities

1. **Declarative MCP management** via home-manager (claude-code.nix)
2. **Claude Code hooks** for automated pre-commit checks
3. **Memory files** (.claude/memory/) for persistent context across sessions
4. **Custom MCP servers** for repo-specific operations (e.g., "add new host", "add new user")
5. **AI-assisted module scaffolding** via templates/generators

### Relevant Projects

- [claude-code.nix](https://github.com/roman/claude-code.nix) — HM module for Claude Code
- [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix) — Nix-based MCP configuration
- [mcps.nix](https://github.com/roman/mcps.nix) — Flake with MCP presets
- [devenv Claude Code integration](https://devenv.sh/integrations/claude-code/)

---

## 9. Issues & Gaps Identified

### Critical Issues

| # | Issue | File | Impact |
|---|-------|------|--------|
| 1 | Hyprland config references KDE-specific `dolphin` | modules/home/desktop/window-managers/hyprland/default.nix:77 | Keybind fails without KDE |
| 2 | MIME association references non-existent `nvim.desktop` | modules/home/xdg/default.nix:20-22 | Editor associations silently fail |
| 3 | Emacs configuration entirely commented out | modules/home/packages/terminal/editors/emacs/default.nix | Users get bare, unconfigured Emacs |
| 4 | Zach user has no desktop.nix | homes/x86_64-linux/zach@eye-of-god/ | No GUI for zach |
| 5 | Only `zach-password` secret; no `skitzo-password` | modules/providers/nixos/security/sops/default.nix | Incomplete secret coverage |

### Architectural Gaps

| # | Gap | Current State | Needed |
|---|-----|---------------|--------|
| 1 | Profiles are stubs | All 4 profiles only enable roles.common | Profile-specific provider composition |
| 2 | Only 1 role (common) | Just enables openssh | Roles for dev, gaming, multimedia, etc. |
| 3 | No CI/CD | No GitHub Actions or Hydra | Automated build/test on commits |
| 4 | No remote deployment | Manual nixos-rebuild only | colmena/deploy-rs integration |
| 5 | No VM tests | No NixOS test infrastructure | Module integration tests |
| 6 | No binary cache | Build from scratch every time | Cachix or self-hosted cache |
| 7 | Pre-commit hooks inactive | Configured but not installed | Shell hook activation in devShell |
| 8 | No direnv | Must manually enter nix develop | .envrc for auto-activation |
| 9 | Single platform | x86_64-linux only | darwin support framework exists but unused |
| 10 | No deployment docs | CLAUDE.md has build commands only | Runbook for deployment, rollback, recovery |

### Code Quality Issues

| # | Issue | Details |
|---|-------|---------|
| 1 | `home/starship.nix` lives outside `modules/` | Inconsistent with module organization |
| 2 | System packages hardcoded in eye-of-god config | Should be composed via profiles/roles |
| 3 | `lib.zyx.*` overlay defined but rarely used | Underutilized abstraction |
| 4 | `nixpkgs-unstable` input used only by standalone HM builder | May be unnecessary |
| 5 | sops validation disabled | Won't catch secret misconfigurations |

---

## 10. Strengths of Current Design

1. **Clean three-layer architecture** — profiles/roles/providers is SOLID-aligned
2. **Auto-discovery system** — hosts and homes discovered from directory structure
3. **Desktop configuration flow** — user preferences aggregate to system-level services
4. **Multi-user support** — each user gets independent HM configuration
5. **Security posture** — SSH hardened, sudo configured, root locked, sops-nix integrated
6. **Extended lib pattern** — clean lib overlay via `lib.zyx.*`
7. **Dev tooling foundation** — treefmt, statix, deadnix all configured
8. **Flake-parts usage** — proper partitioning, module separation
9. **Comprehensive CLAUDE.md** — well-documented for AI assistance
10. **Catppuccin-mocha theming** — system-wide via Stylix

---

## Appendix: Key File Paths

### Configuration Entry Points
- `flake.nix` — Flake definition
- `flake/default.nix` — Flake-parts module root
- `flake/configurations.nix` — NixOS output generation
- `flake/homes.nix` — Home Manager output generation

### Build Pipeline
- `lib/builder/nixos.nix` — System builder
- `lib/builder/home.nix` — Standalone HM builder
- `lib/builder/common.nix` — Shared builder utilities
- `lib/filesystem/default.nix` — Directory discovery
- `lib/overlay/default.nix` — Lib extensions

### Host Configuration
- `systems/x86_64-linux/eye-of-god/default.nix` — Primary host
- `systems/x86_64-linux/eye-of-god/hardware-configuration.nix` — Hardware

### User Configurations
- `homes/x86_64-linux/skitzo@eye-of-god/default.nix` — Primary user
- `homes/x86_64-linux/skitzo@eye-of-god/desktop.nix` — Desktop preference
- `homes/x86_64-linux/zach@eye-of-god/default.nix` — Secondary user

### Module System
- `modules/profiles/default.nix` — Profile index
- `modules/roles/default.nix` — Role index
- `modules/providers/common/nix/default.nix` — Nix/Lix config
- `modules/providers/nixos/services/display/default.nix` — Display aggregation
- `modules/providers/nixos/security/sops/default.nix` — Secrets
- `modules/home/desktop/default.nix` — Desktop routing
