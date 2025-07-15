# Zyx Configuration Implementation Roadmap

This document provides a detailed breakdown of tasks needed to improve the modularity, extensibility, and maintainability of the Zyx NixOS configuration. Tasks are organized by priority and broken down into manageable subtasks.

## Phase 1: Foundation - Platform Detection and Abstraction

### Task 1.1: Implement Platform Detection Module
**Priority: Critical**
**Dependencies: None**

#### Subtasks:
- [ ] Create `modules/platform-detection.nix` with automatic platform detection
- [ ] Add platform type option to `modules/options/system/default.nix`
- [ ] Implement detection logic for nixos/darwin/droid platforms
- [ ] Test platform detection on current NixOS system
- [ ] Update `modules/options/default.nix` to import platform detection

#### Acceptance Criteria:
- Platform is automatically detected and stored in `config.modules.platform.type`
- Detection works for all three target platforms
- No breaking changes to existing configuration

### Task 1.2: Expand Device Capabilities System
**Priority: High**
**Dependencies: Task 1.1**

#### Subtasks:
- [ ] Extend `modules/options/device/capabilities.nix` with comprehensive capability options
- [ ] Add platform-agnostic capabilities (hasGUI, hasNetwork, hasBluetooth)
- [ ] Create platform-specific capability detection logic
- [ ] Update existing `hasAudio` to work with new system
- [ ] Add capability validation functions
- [ ] Document capability system in inline comments

#### Acceptance Criteria:
- All device capabilities are defined as options
- Capabilities are automatically detected based on platform
- Manual override capability exists for edge cases
- Backward compatibility maintained for existing `hasAudio`

### Task 1.3: Create Common Module Architecture
**Priority: High**
**Dependencies: Task 1.1**

#### Subtasks:
- [ ] Create `modules/common/` directory structure
- [ ] Move platform-agnostic configurations to `modules/common/`
- [ ] Create `modules/common/shell/` for shell configurations
- [ ] Create `modules/common/editors/` for editor configurations
- [ ] Create `modules/common/packages/` for universal packages
- [ ] Update imports in existing modules to use common modules
- [ ] Test that all existing functionality still works

#### Acceptance Criteria:
- Platform-agnostic code is separated from platform-specific code
- All common modules work across platforms
- No duplication between platform-specific implementations
- Existing functionality preserved

## Phase 2: Service Abstraction and Package Management

### Task 2.1: Create Service Abstraction Framework
**Priority: High**
**Dependencies: Task 1.1, Task 1.2**

#### Subtasks:
- [ ] Design service abstraction interface in `modules/services/`
- [ ] Create `modules/services/audio/default.nix` with common interface
- [ ] Implement `modules/services/audio/nixos.nix` for NixOS
- [ ] Create placeholder `modules/services/audio/darwin.nix` for future use
- [ ] Add conditional service loading based on platform
- [ ] Test audio service abstraction on current system
- [ ] Document service abstraction pattern

#### Acceptance Criteria:
- Services have platform-agnostic interfaces
- Platform-specific implementations are hidden behind abstractions
- Service enabling/disabling works consistently across platforms
- Audio service works identically to current implementation

### Task 2.2: Implement Centralized Package Management
**Priority: Medium**
**Dependencies: Task 1.1, Task 1.2**

#### Subtasks:
- [ ] Create `modules/packages/default.nix` for centralized package management
- [ ] Define package categories (development, productivity, multimedia, etc.)
- [ ] Implement platform-aware package selection logic
- [ ] Create package availability detection (check if package exists on platform)
- [ ] Move packages from host configurations to centralized system
- [ ] Add package conflict resolution
- [ ] Test package installation on current system

#### Acceptance Criteria:
- All package management is centralized
- Packages are categorized and organized
- Platform-specific packages are handled automatically
- No package conflicts or missing dependencies
- Host configurations are cleaner

### Task 2.3: Create Display/Desktop Environment Abstraction
**Priority: Medium**
**Dependencies: Task 2.1**

#### Subtasks:
- [ ] Create `modules/services/display/` abstraction
- [ ] Abstract X11/Wayland configuration
- [ ] Create desktop environment abstraction (KDE/GNOME/macOS)
- [ ] Implement conditional DE loading based on capabilities
- [ ] Move display configuration from host to abstracted service
- [ ] Test display configuration on current system

#### Acceptance Criteria:
- Display systems are abstracted and platform-agnostic
- Desktop environments can be swapped easily
- Display configuration is moved out of host files
- Current KDE Plasma setup continues to work

## Phase 3: Host Configuration Refactoring

### Task 3.1: Reorganize Host Configuration Structure
**Priority: Medium**
**Dependencies: Task 1.3, Task 2.2**

#### Subtasks:
- [ ] Create `hosts/common/default.nix` for shared host configuration
- [ ] Create `hosts/machines/` directory for individual machines
- [ ] Move `hosts/nixos/eye-of-god/` to `hosts/machines/eye-of-god/`
- [ ] Separate hardware configuration from software preferences
- [ ] Create device profile concept (laptop/desktop/server)
- [ ] Update flake.nix to use new host structure
- [ ] Test that eye-of-god configuration still builds

#### Acceptance Criteria:
- Host configurations are better organized
- Hardware and software concerns are separated
- Device profiles enable easy configuration reuse
- All existing functionality preserved
- Flake continues to build successfully

### Task 3.2: Implement Feature Flag System
**Priority: Medium**
**Dependencies: Task 1.2, Task 2.1**

#### Subtasks:
- [ ] Design feature flag system in `modules/options/features/`
- [ ] Create feature categories (desktop, development, multimedia, gaming)
- [ ] Implement feature dependency resolution
- [ ] Add feature conflict detection
- [ ] Create feature presets for different use cases
- [ ] Update host configurations to use feature flags
- [ ] Test feature enabling/disabling

#### Acceptance Criteria:
- Features can be enabled/disabled declaratively
- Feature dependencies are automatically resolved
- Feature conflicts are detected and reported
- Host configurations are simplified using feature flags
- Easy to create new machine configurations

### Task 3.3: Separate Hardware and Software Configuration
**Priority: Low**
**Dependencies: Task 3.1**

#### Subtasks:
- [ ] Create hardware profile system in `modules/hardware/`
- [ ] Move hardware-specific configuration from hosts
- [ ] Create software profile system in `modules/profiles/`
- [ ] Define common profiles (workstation, development, minimal)
- [ ] Update eye-of-god to use profiles
- [ ] Test profile system functionality

#### Acceptance Criteria:
- Hardware configuration is completely separated
- Software profiles can be mixed and matched
- New machines can be configured by selecting profiles
- Current functionality is preserved

## Phase 4: Cross-Platform Preparation

### Task 4.1: Prepare Darwin Support Infrastructure
**Priority: Low**
**Dependencies: Task 1.1, Task 2.1**

#### Subtasks:
- [ ] Add nix-darwin to flake inputs
- [ ] Create `modules/system/darwin/` structure
- [ ] Implement Darwin-specific service implementations
- [ ] Create Darwin host template in `hosts/templates/`
- [ ] Add Darwin systems to flake outputs
- [ ] Create documentation for Darwin setup

#### Acceptance Criteria:
- Darwin infrastructure is ready for future use
- Service abstractions have Darwin implementations
- Documentation exists for adding macOS machines
- Flake supports Darwin systems (even if unused)

### Task 4.2: Update Flake for Multi-Platform Support
**Priority: Low**
**Dependencies: Task 4.1**

#### Subtasks:
- [ ] Add all target architectures to flake systems
- [ ] Add conditional platform inputs (darwin, nix-on-droid)
- [ ] Update flake outputs to support multiple platforms
- [ ] Add platform-specific package overlays
- [ ] Update flake-parts configuration for multi-platform
- [ ] Test flake evaluation on multiple systems

#### Acceptance Criteria:
- Flake supports x86_64-linux, aarch64-linux, x86_64-darwin, aarch64-darwin
- Platform-specific inputs are conditionally loaded
- Flake evaluation works on all target platforms
- No breaking changes to existing NixOS functionality

### Task 4.3: Implement Unified XDG Configuration
**Priority: Low**
**Dependencies: Task 1.1**

#### Subtasks:
- [ ] Audit existing XDG configuration in `modules/home/xdg/`
- [ ] Add platform-specific XDG directory handling
- [ ] Create unified XDG configuration system
- [ ] Handle macOS Application Support directory mapping
- [ ] Handle Android/Termux home directory mapping
- [ ] Test XDG configuration on current system

#### Acceptance Criteria:
- XDG directories work correctly on all platforms
- Platform-specific directory conventions are respected
- Application configurations use correct paths
- Current XDG setup continues to work

## Phase 5: Testing and Documentation

### Task 5.1: Implement Configuration Testing
**Priority: Medium**
**Dependencies: All previous tasks**

#### Subtasks:
- [ ] Create `tests/` directory structure
- [ ] Implement basic build tests for all configurations
- [ ] Create NixOS VM tests for core functionality
- [ ] Add Darwin build tests (if available)
- [ ] Create CI workflow for automated testing
- [ ] Add integration tests for service abstractions
- [ ] Document testing procedures

#### Acceptance Criteria:
- All configurations can be tested automatically
- CI runs tests on configuration changes
- Regression testing prevents breaking changes
- Test documentation is comprehensive

### Task 5.2: Create Comprehensive Documentation
**Priority: Medium**
**Dependencies: All previous tasks**

#### Subtasks:
- [ ] Create master README.md replacing README.org
- [ ] Document platform setup procedures
- [ ] Create machine configuration guide
- [ ] Document service abstraction system
- [ ] Create troubleshooting guide
- [ ] Add code examples for common tasks
- [ ] Create migration guide from current structure

#### Acceptance Criteria:
- Documentation covers all aspects of the system
- Setup instructions exist for all platforms
- Examples demonstrate common configuration patterns
- Troubleshooting guide addresses likely issues

### Task 5.3: Performance and Maintenance Optimization
**Priority: Low**
**Dependencies: All previous tasks**

#### Subtasks:
- [ ] Audit module evaluation performance
- [ ] Optimize module imports and dependencies
- [ ] Add module caching where appropriate
- [ ] Create maintenance scripts for common tasks
- [ ] Add configuration validation tools
- [ ] Create update and migration utilities

#### Acceptance Criteria:
- Configuration evaluation is performant
- Common maintenance tasks are automated
- Configuration validation catches errors early
- Update procedures are documented and tested

## Implementation Notes

### Recommended Implementation Order:
1. **Start with Phase 1** - Platform detection is foundational
2. **Complete Task 1.1 before others** - Platform detection enables everything else
3. **Implement service abstractions incrementally** - Start with audio, then display
4. **Test thoroughly at each step** - Ensure no regressions
5. **Document as you go** - Don't leave documentation to the end

### Risk Mitigation:
- Keep original configurations as backup during refactoring
- Test each change on the current eye-of-god system
- Implement feature flags to allow rollback if needed
- Use git branches for major structural changes

### Success Metrics:
- Current NixOS configuration continues to work throughout refactoring
- New machine configurations can be created with minimal code
- Platform-specific code is isolated and abstracted
- Configuration evaluation time doesn't significantly increase
- Documentation enables easy onboarding of new machines/platforms

## Future Considerations

After completing this roadmap, consider:
- Secrets management with sops-nix or agenix
- Impermanence implementation
- Disk encryption with disko
- Home server and VPS configurations
- Advanced testing with NixOS test framework
- Configuration optimization and caching strategies