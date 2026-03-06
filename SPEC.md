# Zyx NixOS Configuration Monorepo - Specification

> Version: 1.0 | Date: 2026-02-15 | Status: Draft

## Context

Zyx is a NixOS configuration monorepo managing system and home configurations for multiple users and hosts. The current implementation has a solid three-layer module architecture (profiles/roles/providers) but suffers from:

- **Stub implementations**: All 4 profiles are identical stubs; only 1 role exists
- **No CI/CD, testing, or deployment automation**: Everything is manual
- **Growing specialArgs chains**: Adding cross-cutting concerns requires touching 4+ files
- **Missing developer experience**: Pre-commit hooks inactive, no direnv, basic LSP
- **No remote deployment**: Single host, manual `nixos-rebuild switch` only
- **Critical bugs**: Hyprland references KDE-specific dolphin, broken MIME associations, incomplete emacs config
- **Incomplete secrets management**: Only 1 secret configured, no multi-host strategy

This spec defines the target state across architecture, developer experience, deployment, testing, AI integration, and multi-platform support.

---

## Table of Contents

- [1. Architecture](#1-architecture)
- [2. Developer Experience](#2-developer-experience)
- [3. Deployment & Provisioning](#3-deployment--provisioning)
- [4. Secrets Management](#4-secrets-management)
- [5. Testing](#5-testing)
- [6. AI-Native Integration](#6-ai-native-integration)
- [7. Module System Refactor](#7-module-system-refactor)
- [8. Multi-Platform Support](#8-multi-platform-support)
- [9. Bug Fixes & Cleanup](#9-bug-fixes--cleanup)
- [10. Implementation Phases](#10-implementation-phases)
- [Appendix A: Decision Log](#appendix-a-decision-log)
- [Appendix B: Research References](#appendix-b-research-references)

---

## 1. Architecture

### 1.1 Phased Dendritic Migration

**Decision**: Migrate incrementally from the current specialArgs-based architecture toward the dendritic pattern where features are expressed as flake-parts modules.

**Current state**: Values flow through a builder pipeline:
```
lib/filesystem/ → lib/builder/common.nix → specialArgs → modules
```
Every new cross-cutting concern requires changes in 4+ files.

**Target state**: Two coexisting patterns during migration:
1. **Existing modules**: Continue using specialArgs via `zyx.context.*` module options (see 1.2)
2. **New features**: Written as flake-parts modules using `deferredModule` to inject NixOS/HM config

**Migration strategy**: Per-feature. When a feature is touched, migrate it fully to dendritic style. No bridge modules. Old and new modules are independent.

**Dendritic feature module pattern** (convention will evolve organically):
```nix
# flake/<feature>/default.nix — top-level flake-parts module
{ config, lib, ... }: {
  options.zyx.<feature> = { /* flake-level options */ };

  config.flake.nixosModules.<feature> = { config, pkgs, ... }: {
    # NixOS config — evaluated in NixOS context via deferredModule
  };

  config.flake.homeManagerModules.<feature> = { config, pkgs, ... }: {
    # Home Manager config — evaluated in HM context via deferredModule
  };
}
```

### 1.2 Module Options for Context (Bridge Pattern)

**Decision**: Define `zyx.context.*` NixOS module options to replace raw specialArgs threading.

Create `modules/providers/nixos/context/default.nix`:
```nix
options.zyx.context = {
  hostname = mkOption { type = types.str; };
  users = mkOption { type = types.attrsOf (types.submodule { ... }); };
  # Structured metadata — self-documenting with types and descriptions
};
```

The builder sets `zyx.context.*` once. All NixOS modules read `config.zyx.context.*`. For Home Manager, a thin bridge in the builder extracts what HM needs from `config.zyx.context` and passes via `home-manager.extraSpecialArgs`.

### 1.3 Host Discovery (Hybrid)

**Decision**: Keep filesystem convention for config files, use flake-level options for metadata.

- **Config files**: Stay in `systems/<arch>/<hostname>/default.nix` (hardware, boot, host-specific)
- **Metadata**: Move to flake-level `zyx.hosts.*` options (users, roles, desktop prefs, deploy targets)
- **`lib/filesystem/`**: Simplified — finds directories only, no longer parses `desktop.nix` content
- **`homes/*/desktop.nix`**: Migrated to `zyx.hosts.<hostname>.users.<user>.desktop` options

### 1.4 Three-Layer Module Pattern

**Decision**: Profiles compose roles. Roles compose providers. Roles can have optional package sets.

```
Profile ("What can this host do?")
  └── enables Roles ("What should it be capable of?")
        └── enables Providers ("How is it implemented?")
              └── optional package sets (zyx.roles.<role>.packages.<set>.enable)
```

**Profile design**: Profiles are high-level capability declarations that enable one or more roles.

**Role expansion** (current: only `common`):
- `common` — base for all hosts (SSH, locale, environment)
- `workstation` — desktop environment, audio, display
- `development` — build tools, language servers, editors
- `gaming` — Steam, GPU drivers, gamepad support
- `server` — headless services, monitoring, remote access
- `multimedia` — audio/video production tools

**Roles with package sets** for niche needs:
```nix
zyx.roles.workstation.packages.3d-printing.enable = true;  # prusa-slicer, orca-slicer
zyx.roles.development.packages.embedded.enable = true;      # platformio, etc.
```

### 1.5 SOLID: Dependency Inversion

**Decision**: Abstract where realistic alternatives exist — audio and display services only.

**Abstract interfaces**:
- `zyx.services.audio` — implementations: pipewire (default), pulseaudio
- `zyx.services.display` — implementations: greetd (default), sddm, gdm

**Concrete providers** (no abstraction needed): openssh, sudo, locale, user management

Pattern:
```nix
# modules/providers/nixos/services/audio/default.nix
options.zyx.services.audio = {
  enable = mkEnableOption "audio";
  implementation = mkOption {
    type = types.enum [ "pipewire" "pulseaudio" ];
    default = "pipewire";
  };
};
config = mkIf cfg.enable {
  # Route to implementation module based on cfg.implementation
};
```

### 1.6 Package Management

**Decision**: All packages flow through profiles→roles→providers pipeline. No hardcoded packages in host configs.

Host `default.nix` files contain only:
- Hardware/boot configuration
- Profile selection (`zyx.profiles.workstation.enable = true`)
- Role package set toggles (`zyx.roles.workstation.packages.3d-printing.enable = true`)
- Host-specific overrides via `mkForce`/`mkOverride` (exceptional cases only)

### 1.7 Nix Implementation

**Decision**: Lix required on all hosts. Not configurable per-host.

All hosts use Lix as the Nix implementation. This ensures consistent behavior for experimental features (pipe-operator, auto-allocate-uids, cgroups) across the fleet.

---

## 2. Developer Experience

### 2.1 DevShell (Everything-in-One)

**Decision**: Single comprehensive devShell with all tools.

**Current contents**: nh, deadnix, statix, sops, formatter

**Target contents**:
```
Linting & Formatting:
  - nixfmt-rfc-style (via treefmt)
  - deadnix
  - statix
  - yamlfmt

Language Servers:
  - nixd (workspace-aware, resolves flake outputs and lib.zyx.*)
  - nil (lightweight fallback)

Secrets:
  - sops
  - ssh-to-age (key derivation)
  - age (encryption)

Deployment:
  - colmena
  - nixos-anywhere
  - disko (disk formatting)

Testing:
  - nix-unit (lib/ function tests)

Utilities:
  - nh (NixOS helper)
  - nix-tree (dependency visualization)
  - nix-diff (generation comparison)
```

### 2.2 direnv Integration

Add `.envrc` to repo root:
```
use flake
```

Add `direnv` and `nix-direnv` to system/home config. Entering the repo directory auto-activates the devShell.

### 2.3 Pre-commit Hooks (Activated)

Fix the current issue where hooks are configured but not installed. Ensure the devShell `shellHook` activates git hooks from `git-hooks-nix`.

Hooks:
- `deadnix` — dead code check
- `statix` — Nix linting
- `treefmt` — format validation
- `nix flake check` — eval validation (optional, can be slow)

### 2.4 nixd Configuration

Create `.nixd.json` at repo root for workspace-aware LSP:
```json
{
  "nixpkgs": { "expr": "(builtins.getFlake \"path:.\").inputs.nixpkgs { }" },
  "options": {
    "nixos": { "expr": "(builtins.getFlake \"path:.\").nixosConfigurations.eye-of-god.options" },
    "home-manager": { "expr": "(builtins.getFlake \"path:.\").homeConfigurations.\"skitzo@eye-of-god\".options" }
  }
}
```

This enables nixd to resolve `config.zyx.*` options, `lib.zyx.*` functions, and all module options.

### 2.5 CI/CD (GitHub Actions)

**Pipeline**:
```yaml
on: [push, pull_request]

jobs:
  check:
    - nix flake check           # Eval validation
    - nix fmt -- --check        # Format check

  build:
    - nix build .#nixosConfigurations.eye-of-god.config.system.build.toplevel
    # Repeat for each host

  test:
    - nix build .#checks.x86_64-linux.vm-tests  # NixOS VM tests

  cache:
    - Push built paths to Cachix
```

**Authentication**: Deploy key for zyx-secrets repo (read-only SSH key as GitHub Actions secret).

**Cache**: Cachix free tier initially. Migrate to self-hosted attic when QNAP NAS runs NixOS.

---

## 3. Deployment & Provisioning

### 3.1 Colmena Integration

**Decision**: Colmena for ongoing multi-host deployment.

Add `colmena` flake input and configure via flake-parts module:

```nix
# flake/deploy.nix
{ config, ... }: {
  flake.colmena = {
    meta = {
      nixpkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
      specialArgs = { inherit inputs; };
    };

    eye-of-god = {
      deployment = {
        targetHost = /* from secrets repo */;
        targetPort = 30;
        targetUser = "root";
      };
      imports = [ ./systems/x86_64-linux/eye-of-god ];
    };

    # Additional hosts...
  };
}
```

### 3.2 nixos-anywhere for Provisioning

**Decision**: nixos-anywhere + disko for initial host bootstrapping.

Each host defines declarative disk layout:
```nix
# systems/<arch>/<hostname>/disko.nix
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/nvme0n1";
    content = { /* partitions, filesystems */ };
  };
}
```

**eye-of-god**: Keep existing `hardware-configuration.nix`. Add disko config alongside it. New hosts use disko exclusively.

### 3.3 Unified Installation Script

Interactive script handling the full lifecycle:

```
zyx-install <hostname>

Phase 1: Provisioning (nixos-anywhere)
  - Validate host config exists in systems/<arch>/<hostname>/
  - Partition disks via disko
  - Install base NixOS (without secrets)

Phase 2: Key Exchange (interactive)
  - Script pauses
  - Displays instructions: "SSH into host, run: ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
  - Operator adds age key to .sops.yaml
  - Operator re-encrypts secrets: sops updatekeys secrets/<hostname>/secrets.yaml
  - Operator confirms completion

Phase 3: Full Deployment (colmena)
  - Deploy complete configuration with secrets
  - Verify services are running
  - Report success/failure
```

### 3.4 Host Target Count

**Near-term**: 3-4 hosts
- `eye-of-god` — Framework 13" laptop (workstation/development/gaming)
- QNAP NAS → NixOS server (server profile, binary cache host)
- Additional machines as needed

---

## 4. Secrets Management

### 4.1 Current State

- sops-nix with age encryption
- Single `secrets.yaml` in zyx-secrets repo
- Only `zach-password` configured
- Validation disabled

### 4.2 Target State

**Per-host secrets isolation**:
```
zyx-secrets/
├── .sops.yaml              # Creation rules per host
├── sops/
│   ├── common/
│   │   └── secrets.yaml    # Shared secrets (if any)
│   ├── eye-of-god/
│   │   └── secrets.yaml    # Host-specific secrets
│   └── <new-host>/
│       └── secrets.yaml
└── deploy/
    └── hosts.yaml          # Unencrypted deployment metadata (IPs, ports)
```

**Deploy connection details**: Stored in secrets repo as unencrypted YAML (IPs and SSH ports aren't sensitive enough to warrant encryption, but shouldn't be in the public config repo).

**Secrets to configure**:
- User passwords (per-user, per-host)
- SSH private keys (optional, for automated access)
- API tokens (as needed)
- Wireless network credentials
- VPN configurations

**Enable validation**: Set `validateSopsFiles = true` to catch misconfigurations at build time.

### 4.3 CI/CD Authentication

Deploy key (SSH) as GitHub Actions secret. Read-only access to zyx-secrets. Only used during build evaluation — secrets aren't decrypted in CI, only referenced.

---

## 5. Testing

### 5.1 Testing Levels

| Level | Tool | What It Validates |
|-------|------|-------------------|
| **Eval** | `nix flake check` | Syntax, types, option validation |
| **Format** | `nix fmt -- --check` | Code style consistency |
| **Lint** | `statix`, `deadnix` | Code quality, dead code |
| **Unit** | `nix-unit` | `lib/` functions (filesystem discovery, builder logic) |
| **Build** | `nix build` | Full system closure builds successfully |
| **VM Integration** | `nixosTest` | Services start, users exist, secrets decrypt |
| **VM Login** | `nixosTest` + PAM | User login simulation, session env validation |

### 5.2 VM Test Scope

**Service tests** (headless QEMU):
- SSH daemon starts and is reachable on configured port
- User accounts exist with correct groups
- Secrets are decrypted and accessible
- Nix daemon is running
- Firewall rules are correct

**Desktop tests** (login simulation):
- greetd starts and accepts connections
- Desktop sessions (KDE, Hyprland) are registered and available
- User login via PAM succeeds
- Session environment variables are set (`XDG_SESSION_TYPE`, `NIXOS_OZONE_WL`)
- Display manager offers correct sessions per user desktop preference

**Multi-user tests**:
- Multiple users with different desktop preferences coexist
- User without desktop.nix gets no GUI session
- User isolation (home directories, permissions)

### 5.3 Lib Unit Tests

Test `lib/filesystem/` functions:
- `getDirectoryNames` returns correct dirs
- `parseDelimittedHomeConfigIdentifier` parses `user@host` correctly
- `genHostConfigMetadataForSystem` generates correct metadata
- Edge cases: empty dirs, missing desktop.nix, malformed identifiers

---

## 6. AI-Native Integration

### 6.1 Nix-Managed Claude Code Config

**Decision**: Home Manager manages Claude Code configuration declaratively.

Evaluate and integrate [claude-code.nix](https://github.com/roman/claude-code.nix) or create a custom HM module:

```nix
# modules/home/ai/default.nix
programs.claude-code = {
  enable = true;
  settings = { /* .claude/settings.json content */ };
  mcpServers = {
    mcp-nixos = {
      command = "mcp-nixos";
      args = [];
    };
    # Additional MCP servers as needed
  };
};
```

This generates `.mcp.json` and `.claude/settings.json` declaratively. Project-level overrides stay in the repo.

### 6.2 CLAUDE.md Maintenance

Keep CLAUDE.md updated as the architecture evolves. Key sections:
- Commands (build, test, deploy, format)
- Architecture (three-layer system, dendritic features, build pipeline)
- Conventions (namespacing, file layout, module patterns)
- Special args and context options available in modules

### 6.3 Memory Files

Use `.claude/memory/` for persistent cross-session knowledge:
- `MEMORY.md` — key patterns, conventions, user preferences
- Topic-specific files as needed (debugging, patterns, etc.)

### 6.4 Hooks

Configure Claude Code hooks for automated validation:
- Pre-commit: `nix fmt -- --check` on changed files
- Post-edit: `statix check` on modified Nix files

---

## 7. Module System Refactor

### 7.1 Profile Expansion

Flesh out stub profiles to compose meaningful role sets:

```nix
# modules/profiles/workstation/default.nix
config = mkIf cfg.enable {
  zyx.roles.common.enable = true;
  zyx.roles.workstation.enable = true;
};

# modules/profiles/development/default.nix
config = mkIf cfg.enable {
  zyx.roles.common.enable = true;
  zyx.roles.development.enable = true;
};

# modules/profiles/gaming/default.nix
config = mkIf cfg.enable {
  zyx.roles.common.enable = true;
  zyx.roles.workstation.enable = true;  # Gaming needs a desktop
  zyx.roles.gaming.enable = true;
};

# modules/profiles/server/default.nix
config = mkIf cfg.enable {
  zyx.roles.common.enable = true;
  zyx.roles.server.enable = true;
};
```

### 7.2 Role Expansion

Each role enables specific providers and declares optional package sets:

```nix
# modules/roles/workstation/default.nix
options.zyx.roles.workstation = {
  enable = mkEnableOption "workstation role";
  packages = {
    3d-printing = { enable = mkEnableOption "3D printing tools"; };
    # ... other optional package sets
  };
};

config = mkIf cfg.enable {
  zyx.services.audio.enable = true;
  zyx.services.display.enable = true;
  zyx.services.pipewire.enable = true;
  # Package sets
  environment.systemPackages = mkIf cfg.packages.3d-printing.enable [
    pkgs.prusa-slicer
    pkgs.orca-slicer
  ];
};
```

### 7.3 Provider Abstraction (Audio + Display)

**Audio**:
```nix
options.zyx.services.audio = {
  enable = mkEnableOption "audio";
  implementation = mkOption {
    type = types.enum [ "pipewire" "pulseaudio" ];
    default = "pipewire";
  };
};
```

**Display**:
```nix
options.zyx.services.display = {
  enable = mkEnableOption "display manager";
  implementation = mkOption {
    type = types.enum [ "greetd" "sddm" "gdm" ];
    default = "greetd";
  };
};
```

### 7.4 Host Config Cleanup

Move all packages from `systems/x86_64-linux/eye-of-god/default.nix` into roles/providers:

| Current Location | Target |
|-----------------|--------|
| `firefox` | `roles/workstation` provider |
| `neovim`, `gcc`, `clang`, `ripgrep`, `fd`, `tree` | `roles/development` provider |
| `nil`, `statix`, `deadnix`, `nixfmt-rfc-style` | DevShell only (not system packages) |
| `prusa-slicer`, `orca-slicer` | `roles/workstation.packages.3d-printing` |
| `vscodium` | `roles/development` provider |
| `claude-code`, `mcp-nixos` | AI module / DevShell |
| `alejandra` | Remove (using nixfmt-rfc-style via treefmt) |

### 7.5 Stale File Cleanup

- Move `home/starship.nix` → `modules/home/packages/terminal/shell/starship/default.nix`
- Remove or complete `modules/home/packages/terminal/editors/emacs/default.nix`

---

## 8. Multi-Platform Support

### 8.1 Darwin Planning

**Decision**: Plan for darwin support now in all architectural decisions.

**Actions**:
- Ensure module options have platform conditionals (`lib.mkIf pkgs.stdenv.isLinux`)
- Add `providers/darwin/` directory structure (empty stubs)
- Extend `lib/builder/` with `buildDarwinSystem` (nix-darwin integration)
- Add `filterDarwinHosts` usage in `flake/configurations.nix`
- Roles/profiles include darwin-compatible alternatives where applicable
- `flake.nix` `systems` list includes `aarch64-darwin` and `x86_64-darwin`

**Not implemented now**: Actual darwin host configurations. Framework only.

### 8.2 Architecture-Agnostic Modules

Providers in `modules/providers/common/` should work on all platforms. NixOS-specific providers stay in `modules/providers/nixos/`. Darwin-specific providers will go in `modules/providers/darwin/`.

Home Manager modules (`modules/home/`) should be platform-agnostic where possible, with conditional imports for platform-specific features.

---

## 9. Bug Fixes & Cleanup

### 9.1 Critical Bugs

| # | Bug | Fix | Status |
|---|-----|-----|--------|
| 1 | Hyprland references `dolphin` (KDE-specific) at `modules/home/desktop/window-managers/hyprland/default.nix:77` | Replaced with `thunar`, added thunar to Hyprland packages | **DONE** |
| 2 | MIME associations reference non-existent `nvim.desktop` at `modules/home/xdg/default.nix` | Created `xdg.desktopEntries.neovim` desktop entry, updated references to `neovim.desktop` | **DONE** |
| 3 | Emacs config entirely commented out at `modules/home/packages/terminal/editors/emacs/default.nix` | Removed emacs module entirely (can be re-added when config is ready) | **DONE** |
| 4 | Zach user has no `desktop.nix` — no GUI access | Documented as intentional headless user in zach's home config | **DONE** |
| 5 | Only `zach-password` secret — no `skitzo-password` | Added `skitzo-password` to sops secrets config (still needs entry in zyx-secrets repo) | **DONE** |

### 9.2 Code Quality

| # | Issue | Fix | Status |
|---|-------|-----|--------|
| 1 | sops `validateSopsFiles = false` | Enable validation | Pending (blocked on secrets repo having all entries) |
| 2 | `alejandra` installed as system package alongside `nixfmt-rfc-style` | Removed alejandra from system packages | **DONE** |
| 3 | Nix dev tools (nil, statix, deadnix, nixfmt) as system packages | Removed from system packages (belong in devShell) | **DONE** |
| 4 | `nixpkgs-unstable` input only used by standalone HM builder | Evaluate if needed; both point to nixos-unstable | Pending |

---

## 10. Implementation Phases

### Phase 0: Bug Fixes & Cleanup (Foundation) — **COMPLETE**
1. ~~Fix all 5 critical bugs (Section 9.1)~~ **DONE**
2. ~~Clean up code quality issues (Section 9.2)~~ **DONE** (sops validation + nixpkgs-unstable deferred)
3. ~~Move `home/starship.nix` into module hierarchy~~ **DONE** — moved to `modules/home/packages/terminal/shell/starship/default.nix`
4. Commit clean baseline

### Phase 1: Developer Experience (Priority)
1. Enhance devShell with all tools (Section 2.1)
2. Add `.envrc` for direnv auto-activation (Section 2.2)
3. Activate pre-commit hooks (Section 2.3)
4. Add `.nixd.json` for workspace-aware LSP (Section 2.4)
5. Set up GitHub Actions CI/CD pipeline (Section 2.5)
6. Configure Cachix binary cache

### Phase 2: Architecture Refactor
1. Create `zyx.context.*` module options (Section 1.2)
2. Refactor builder pipeline to set context options
3. Flesh out profiles to compose roles (Section 7.1)
4. Expand roles (workstation, development, gaming, server, multimedia) (Section 7.2)
5. Add provider abstraction for audio + display (Section 7.3)
6. Move host packages into roles/providers (Section 7.4)
7. Add darwin directory stubs and builder support (Section 8.1)

### Phase 3: Testing Infrastructure
1. Add nix-unit tests for `lib/` functions (Section 5.3)
2. Create NixOS VM tests for services (Section 5.2)
3. Add login simulation tests for desktop (Section 5.2)
4. Integrate tests into CI pipeline

### Phase 4: Deployment & Secrets
1. Integrate colmena (Section 3.1)
2. Add disko configs for new hosts (Section 3.2)
3. Create unified installation script (Section 3.3)
4. Restructure secrets repo for multi-host (Section 4.2)
5. Enable sops validation
6. Configure CI deploy key (Section 4.3)

### Phase 5: AI-Native & Polish
1. Create HM module for Claude Code config (Section 6.1)
2. Update CLAUDE.md for new architecture (Section 6.2)
3. Configure Claude Code hooks (Section 6.4)
4. Begin dendritic migration of first feature (Section 1.1)

---

## Appendix A: Decision Log

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Architecture migration | Phased dendritic | Incremental adoption, lower risk than full rewrite |
| 2 | Profile design | Profiles compose roles | Maintains three-layer separation |
| 3 | Host discovery | Hybrid (dirs + flake options) | Config in dirs, metadata in options |
| 4 | Data passing | Module options (zyx.context.*) | Self-documenting, stepping stone to dendritic |
| 5 | Secret bootstrap | Two-phase with interactive prompts | Explicit, auditable, no pre-shared keys |
| 6 | Disk management | Disko (new hosts) | Required for nixos-anywhere automation |
| 7 | Testing scope | Comprehensive VM + login simulation | High confidence for multi-user desktop configs |
| 8 | Desktop VM testing | Login simulation | Verifies PAM, sessions, env vars without needing GPU |
| 9 | Migration boundary | Per-feature | Clean separation, no bridge modules |
| 10 | DevShell scope | Everything in one shell | Simple DX, single nix develop |
| 11 | Darwin support | Plan now, implement later | Future-proof architecture decisions |
| 12 | SOLID DI | Abstract audio + display only | Only where realistic alternatives exist |
| 13 | Package management | Everything through pipeline | No hardcoded packages in host configs |
| 14 | Language server | Both nixd + nil available | nixd for full resolution, nil as fallback |
| 15 | Nix implementation | Lix required everywhere | Consistent experimental feature support |
| 16 | AI config management | Nix-managed via home-manager | Single source of truth, declarative |
| 17 | Binary cache | Cachix → self-hosted attic | Free tier now, QNAP NAS later |
| 18 | Deploy connection details | Secrets repo (encrypted + unencrypted) | IPs in cleartext, credentials encrypted |
| 19 | Niche packages | Roles with package sets | Stays in pipeline without profile proliferation |
| 20 | Dendritic convention | Evolve organically | Avoid premature standardization |
| 21 | Implementation priority | DX first | Great workflow enables faster subsequent work |
| 22 | CI secrets auth | Deploy key (SSH) | Standard pattern, read-only access |
| 23 | Target host count | 3-4 hosts | Laptop + NAS + additional machines |

---

## Appendix B: Research References

### Flake-Parts
- [flake.parts](https://flake.parts/) — Official documentation
- [Partitions reference](https://flake.parts/options/flake-parts-partitions)
- [Best practices for module writing](https://flake.parts/best-practices-for-module-writing.html)

### Dendritic Pattern
- [Dendritic GitHub](https://github.com/mightyiam/dendritic)
- [NixCon 2025 talk](https://talks.nixcon.org/nixcon-2025/talk/REJ3LF/)
- [Discourse discussion](https://discourse.nixos.org/t/pattern-every-file-is-a-flake-parts-module/61271)
- [Dendritic with flake-parts FAQ](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ)

### Deployment
- [Colmena docs](https://colmena.cli.rs/)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [disko](https://github.com/nix-community/disko)
- [Remote Deployment - NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)

### Secrets
- [sops-nix](https://github.com/Mic92/sops-nix)
- [NixOS Secrets Management](https://unmovedcentre.com/posts/secrets-management/)

### AI Integration
- [claude-code.nix](https://github.com/roman/claude-code.nix)
- [mcp-servers-nix](https://github.com/natsukium/mcp-servers-nix)
- [MCP-NixOS](https://mcp-nixos.io/)

### Testing
- [NixOS VM tests](https://nixos.org/manual/nixos/stable/#sec-nixos-tests)
- [nix-unit](https://github.com/nix-community/nix-unit)
