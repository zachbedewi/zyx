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

### Task 5.1.1: Device Options Module Testing Implementation
**Priority: High**
**Dependencies: Task 1.2 (Device Capabilities System)**

#### Overview:
Implement comprehensive testing for the device options module using modern NixOS testing frameworks. This includes unit testing for individual module logic and integration testing for complete system configurations.

#### Testing Strategy:
**Unit Testing (NixTest Framework)**
- Test option defaults and type validation
- Test capability dependency assertions
- Test edge cases and error conditions

**Integration Testing (NixOS Test Framework)**  
- Test module integration in VM environments
- Test capability detection on different hardware profiles
- Test cross-module dependencies

**Configuration Validation Testing**
- Test all device type configurations
- Test capability combination matrix
- Test assertion failure scenarios

#### Subtasks:
- [ ] Create `tests/unit/device/` directory structure
- [ ] Implement NixTest unit tests for `capabilities.nix`:
  - [ ] Test `hasAudio` option defaults and validation
  - [ ] Test `hasGUI` option behavior
  - [ ] Test `hasGPU` option and GPU detection logic
  - [ ] Test `hasWayland` option dependency on GPU and Linux
  - [ ] Test `supportsCompositing` capability combinations
  - [ ] Test assertion validation for capability dependencies
- [ ] Implement NixTest unit tests for `hardware.nix`:
  - [ ] Test device type enumeration (laptop/desktop/server/vm)
  - [ ] Test device type validation assertions
  - [ ] Test null/empty device type error handling
- [ ] Create `tests/integration/device/` directory structure
- [ ] Implement NixOS integration tests:
  - [ ] Test laptop configuration with all capabilities enabled
  - [ ] Test desktop configuration with GPU and Wayland support
  - [ ] Test server configuration (headless, no GUI)
  - [ ] Test VM configuration with minimal capabilities
  - [ ] Test capability detection in different hardware scenarios
  - [ ] Test cross-module interactions (device + services)
- [ ] Create configuration validation test suite:
  - [ ] Test valid capability combinations
  - [ ] Test invalid capability combinations (should fail assertions)
  - [ ] Test edge cases (Wayland without GPU, compositing without GUI)
  - [ ] Test device type migration scenarios
- [ ] Add tests to flake `checks` output for CI integration
- [ ] Create test documentation and examples
- [ ] Add performance benchmarks for module evaluation

#### Implementation Files:
```
tests/
├── unit/device/
│   ├── capabilities-test.nix          # Unit tests for capabilities.nix
│   ├── hardware-test.nix              # Unit tests for hardware.nix
│   └── default-test.nix               # Unit tests for default.nix
├── integration/device/
│   ├── laptop-config-test.nix         # Laptop configuration integration test
│   ├── desktop-config-test.nix        # Desktop configuration integration test
│   ├── server-config-test.nix         # Server configuration integration test
│   ├── vm-config-test.nix             # VM configuration integration test
│   └── capability-detection-test.nix  # Hardware capability detection test
├── validation/device/
│   ├── valid-combinations-test.nix    # Test valid capability combinations
│   ├── invalid-combinations-test.nix  # Test assertion failures
│   └── edge-cases-test.nix            # Test boundary conditions
└── lib/
    ├── test-utils.nix                 # Common testing utilities
    └── mock-hardware.nix              # Mock hardware configurations
```

#### Testing Framework Setup:
- **NixTest**: Pure Nix unit testing framework for individual module logic
- **NixOS Test Framework**: VM-based integration testing for complete configurations  
- **Flake Integration**: All tests accessible via `nix flake check`
- **CI Integration**: Automated testing on configuration changes

#### Acceptance Criteria:
- All device option functionality is covered by unit tests
- Integration tests validate module behavior in real NixOS configurations
- Test suite catches capability dependency violations
- All tests run successfully via `nix flake check`
- Test documentation explains how to add new tests
- Performance regression testing prevents evaluation slowdowns
- Test suite serves as documentation for module behavior

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

## Current Work-in-Progress Status

### Task 6.3: Hyprland Core Module (PARTIALLY COMPLETE)
**Status**: System-level configuration complete, Home Manager integration in progress

**Completed Work**:
- ✅ Enhanced device capabilities with Wayland, GPU, and compositing detection
- ✅ Created display/desktop environment abstraction framework  
- ✅ Successfully migrated Plasma configuration to use abstraction
- ✅ Implemented system-level Hyprland module with package management and service configuration
- ✅ Added capability checks and environment variables

**Work in Progress**:
- 🔄 Migrating user-specific Hyprland configuration to Home Manager modules
- 🔄 Creating template-based and hybrid configuration approaches
- ⏳ User configuration files (hyprland.conf) moved to `modules/home/desktop/wayland/hyprland/`

**Next Session Tasks**:
1. Complete Home Manager Hyprland module with template/hybrid/custom configuration methods
2. Integrate Home Manager desktop modules into main home configuration
3. Test Hyprland activation as alternative to Plasma
4. Begin Task 6.4: System integration (audio, theming, terminal, packages)

**File Structure Created**:
```
modules/
├── system/nixos/services/display/          # System-level DE abstraction
│   ├── default.nix                         # Main display service interface
│   ├── x11/plasma.nix                      # Plasma configuration (migrated)
│   └── wayland/hyprland/default.nix        # Hyprland system config
└── home/desktop/wayland/hyprland/          # User-specific config (WIP)
    └── hyprland.conf                       # Template config file
```

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

## Phase 6: Hyprland Window Manager Integration

### Task 6.1: Enhance Device Capabilities for Wayland Support
**Priority: High**
**Dependencies: Task 1.2**

#### Requirements Analysis:
- **Cross-platform compatibility**: Designed for future Linux distro support
- **Alternative DE**: Hyprland as alternative to current desktop environment
- **Layered architecture**: Service abstraction + feature flag + standalone module
- **Configuration approach**: Both hybrid and template-based for comparison
- **Ecosystem scope**: Core Hyprland initially, then Hyprpaper/Hyprlock/Hypridle
- **System integration**: Full integration with audio, theming, terminal, packages
- **Capability-driven**: Depends on hasGUI, hasWayland, supportsCompositing, GPU detection
- **Multi-DE support**: Ability to switch between Plasma/Hyprland
- **Configuration scope**: Personal use case, not general-purpose Nix module

#### Subtasks:
- [x] Add `hasWayland` capability to `modules/options/device/capabilities.nix`
- [x] Add `supportsCompositing` capability with GPU detection logic
- [x] Add `hasGPU` capability with basic GPU hardware detection
- [x] Extend `hasGUI` capability (if not already present)
- [x] Create capability dependency validation (Wayland requires GUI, etc.)
- [x] Test capability detection on current system

#### Acceptance Criteria:
- New capabilities are properly detected on the current system
- Capability dependencies are validated and enforced
- GPU detection works for common graphics drivers
- Wayland capability correctly identifies Wayland support

### Task 6.2: Create Display/Desktop Environment Abstraction Framework
**Priority: High**
**Dependencies: Task 6.1, Task 2.1**

#### Subtasks:
- [x] Create `modules/services/display/` directory structure
- [x] Design desktop environment abstraction interface in `modules/services/display/default.nix`
- [x] Create `modules/services/display/x11/` for X11-based environments
- [x] Create `modules/services/display/wayland/` for Wayland-based environments
- [x] Implement current Plasma configuration as `modules/services/display/x11/plasma.nix`
- [x] Add desktop environment selection option in `modules/options/user/desktop.nix`
- [x] Create conditional loading based on selected DE and capabilities
- [x] Test current Plasma setup continues working through abstraction

#### Acceptance Criteria:
- Desktop environments are properly abstracted
- Current Plasma configuration works identically through new abstraction
- DE selection is capability-aware (won't load Wayland DE without Wayland support)
- Foundation exists for multiple DE support

### Task 6.3: Implement Hyprland Core Module
**Priority: High**
**Dependencies: Task 6.2**

#### Subtasks:
- [x] Create `modules/services/display/wayland/hyprland/` directory structure
- [x] Implement `modules/services/display/wayland/hyprland/default.nix` main module
- [x] Add Hyprland package management and service configuration
- [ ] Create basic Hyprland configuration template system (IN PROGRESS - moved to Home Manager)
- [ ] Implement hybrid configuration approach (Nix base + user overrides)
- [x] Add Hyprland-specific capability checks (Wayland, GPU, compositing)
- [x] Create Hyprland environment variables and session setup
- [ ] Test Hyprland activation without breaking existing Plasma setup

#### Implementation Notes:
- **Architecture Decision**: Moved user-specific Hyprland configuration to Home Manager modules rather than system-level
- **Rationale**: Different users should be able to choose different desktop environments
- **Current State**: System-level module handles Hyprland enablement, XDG portals, and essential packages
- **Next Steps**: Complete Home Manager module for user-specific Hyprland configuration (templates, hybrid, custom methods)

#### Acceptance Criteria:
- Hyprland can be enabled as alternative to Plasma
- Basic Hyprland session starts and functions
- Configuration template system works
- Hybrid configuration allows user customizations
- No interference with existing Plasma configuration

### Task 6.4: Integrate Hyprland with Existing Systems
**Priority: Medium**
**Dependencies: Task 6.3**

#### Subtasks:
- [ ] Integrate Hyprland with existing audio abstraction (PipeWire/PulseAudio)
- [ ] Add Stylix theme integration for Hyprland
- [ ] Configure Kitty terminal to work optimally with Hyprland
- [ ] Add Hyprland-specific packages to centralized package management
- [ ] Create Hyprland-specific XDG desktop portal configuration
- [ ] Implement proper session management and login integration
- [ ] Test all integrations work correctly

#### Acceptance Criteria:
- Audio works correctly in Hyprland sessions
- Stylix theming applies to Hyprland
- Terminal integration is seamless
- All necessary packages are automatically installed with Hyprland
- Desktop portals function properly

### Task 6.5: Implement Desktop Environment Feature Flag System
**Priority: Medium**
**Dependencies: Task 6.4, Task 3.2 (when implemented)**

#### Subtasks:
- [ ] Add desktop environment feature flags to `modules/options/features/`
- [ ] Create `features.desktop.plasma.enable` option
- [ ] Create `features.desktop.hyprland.enable` option
- [ ] Implement mutual exclusion logic (prevent both DEs active simultaneously)
- [ ] Add DE-specific feature dependencies (Hyprland requires Wayland features)
- [ ] Create feature presets for different use cases
- [ ] Update host configurations to use DE feature flags
- [ ] Test feature flag switching between DEs

#### Acceptance Criteria:
- Desktop environments can be enabled/disabled via feature flags
- Mutual exclusion prevents conflicts
- Feature dependencies are automatically resolved
- Easy switching between Plasma and Hyprland
- Host configurations are simplified

### Task 6.6: Implement Template and Hybrid Configuration Systems
**Priority: Medium**
**Dependencies: Task 6.3**

#### Subtasks:
- [ ] Create Hyprland configuration template in `modules/services/display/wayland/hyprland/templates/`
- [ ] Implement template generation with Nix string interpolation
- [ ] Create user override system for hybrid approach
- [ ] Add configuration validation for both approaches
- [ ] Create example configurations demonstrating both methods
- [ ] Document configuration approaches and trade-offs
- [ ] Test both configuration methods work correctly

#### Acceptance Criteria:
- Template-based configuration generates valid Hyprland config
- Hybrid approach allows user customizations without conflicts
- Configuration validation catches common errors
- Documentation explains both approaches clearly
- User can choose preferred configuration method

### Task 6.7: Prepare Hyprland Ecosystem Extensions
**Priority: Low**
**Dependencies: Task 6.6**

#### Subtasks:
- [ ] Create extension framework in `modules/services/display/wayland/hyprland/extensions/`
- [ ] Design Hyprpaper wallpaper daemon integration
- [ ] Design Hyprlock screen locker integration
- [ ] Design Hypridle idle daemon integration
- [ ] Create extension capability detection
- [ ] Implement extension configuration templates
- [ ] Document extension system for future development

#### Acceptance Criteria:
- Extension framework is ready for future implementation
- Hyprpaper, Hyprlock, and Hypridle designs are documented
- Extension system integrates with main Hyprland configuration
- Framework supports both template and hybrid configuration approaches

## Future Considerations

After completing this roadmap, consider:
- Secrets management with sops-nix or agenix
- Impermanence implementation
- Disk encryption with disko
- Home server and VPS configurations
- Advanced testing with NixOS test framework
- Configuration optimization and caching strategies
- Hyprland ecosystem completion (Hyprpaper, Hyprlock, Hypridle)
- Additional Wayland compositors (Sway, River, etc.)
- Status bar integration (Waybar, Eww, etc.)
- Application launcher integration (wofi, rofi-wayland, etc.)