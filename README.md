# Zyx - Advanced NixOS Configuration Framework

A modular, testable, and cross-platform configuration management system built on Nix flakes with comprehensive service abstractions and capability-driven configuration.

[![Tests](https://img.shields.io/badge/tests-213%20passing-brightgreen)](#testing)
[![Architecture](https://img.shields.io/badge/architecture-modular-blue)](#architecture)
[![Platform](https://img.shields.io/badge/platform-nixos%20%7C%20darwin-lightgrey)](#platform-support)

## ✨ Features

### 🏗️ **Modern Architecture**
- **Service Abstraction Layer**: Platform-agnostic APIs with platform-specific implementations
- **Capability-Driven Configuration**: Hardware detection drives feature availability  
- **Comprehensive Testing**: 213 automated tests ensuring reliability
- **Type Safety**: Strong validation and assertions prevent configuration errors

### 🔧 **Service Management**
- **Audio**: Cross-platform audio with PipeWire/PulseAudio/CoreAudio support
- **Display**: X11/Wayland/Quartz backends with desktop environment abstraction
- **Networking**: WiFi, VPN, firewall, and DNS management with multiple backends
- **Security**: Multi-level hardening with compliance framework integration
- **SSH**: Hardened server/client with automated key management
- **Secrets**: Secure storage with SOPS/agenix/age/GPG backend support

### 🖥️ **Platform Support**
- **NixOS**: Full implementation with systemd integration
- **Darwin**: Foundation ready for macOS support
- **Cross-Platform**: Unified configuration across different systems

### 🔒 **Security-First Design**
- Hardware-aware encryption (TPM, Hardware RNG, Memory Protection)
- Automated secret rotation and lifecycle management
- Compliance frameworks (CIS, NIST, ISO27001)
- Comprehensive audit logging with tamper protection

## 🚀 Quick Start

### Prerequisites
- Nix with flakes enabled
- Git for version control

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/zyx.git
   cd zyx
   ```

2. **Test the configuration**:
   ```bash
   nix flake check
   ```

3. **Build for your system**:
   ```bash
   # For NixOS
   sudo nixos-rebuild switch --flake .
   
   # For specific host (Framework 13" laptop)
   sudo nixos-rebuild switch --flake .#eye-of-god
   ```

### Current Host Configuration

**eye-of-god** - Framework 13" Laptop (Primary Development Machine)
- **Platform**: NixOS x86_64-linux
- **Desktop**: KDE Plasma with Wayland support
- **Audio**: PipeWire with professional audio tools
- **Security**: Standard hardening with TPM integration
- **Features**: Development environment, multimedia support, gaming optimizations

This configuration serves as the reference implementation and testing ground for all new features.

## 📋 Common Commands

### System Management

```bash
# Build and activate system configuration
sudo nixos-rebuild switch --flake .

# Test configuration without activating
sudo nixos-rebuild test --flake .

# Build in VM for testing
nixos-rebuild build-vm --flake .

# Check flake syntax and evaluate all configurations  
nix flake check

# Update flake inputs
nix flake update

# Show flake info and outputs
nix flake show
```

### Development and Testing

```bash
# Run all tests
nix flake check

# Test specific modules
nix eval --impure --expr '(import ./tests { 
  pkgs = import <nixpkgs> {}; 
  lib = (import <nixpkgs> {}).lib; 
}).results'

# Check device capabilities
show-capabilities  # Available after system build

# Format Nix code (if formatter is configured)
nix fmt

# Enter development shell
nix develop
```

### Service Management

```bash
# Check service status
systemctl status audio-service
systemctl status networking-service
systemctl status secrets-*

# View service logs
journalctl -u secrets-rotation
journalctl -u secrets-backup

# Reload systemd configuration
sudo systemctl daemon-reload
```

## 🏛️ Architecture

### Directory Structure

```
zyx/
├── flake.nix                    # Main flake with test integration
├── modules/
│   ├── platform/               # Platform detection and capabilities
│   │   ├── detection.nix       # Platform detection (nixos/darwin/droid)
│   │   └── capabilities.nix    # Device capabilities and profiles
│   ├── services/               # Service abstractions
│   │   ├── audio/              # Cross-platform audio management
│   │   ├── display/            # Display and desktop environments
│   │   ├── networking/         # Network, WiFi, VPN, firewall
│   │   ├── security/           # System hardening and monitoring
│   │   ├── ssh/                # SSH server/client management
│   │   └── secrets/            # Secret storage and lifecycle
│   ├── options/ (legacy)       # Legacy options - being phased out
│   ├── system/ (legacy)        # Legacy system modules
│   └── home/ (legacy)          # Legacy home modules
├── tests/                      # Comprehensive testing framework
│   ├── lib/                    # Test utilities and mock hardware
│   └── unit/                   # Unit tests for all modules
└── hosts/                      # Host configurations
    └── nixos/eye-of-god/       # Framework 13" laptop configuration
```

### Service Abstraction Pattern

All services follow a consistent interface/implementation pattern:

```nix
# modules/services/example/interface.nix - Platform-agnostic API
{ lib, config, ... }: {
  options.services.example = {
    enable = lib.mkOption { /* ... */ };
    # Service-specific options
  };
  
  config = lib.mkIf config.services.example.enable {
    # Capability assertions and auto-configuration
  };
}

# modules/services/example/nixos.nix - Platform-specific implementation  
{ lib, config, pkgs, ... }: {
  config = lib.mkIf (
    config.services.example.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    # NixOS-specific implementation
  };
}
```

## 🔧 Configuration Examples

### Basic Service Configuration

```nix
# Enable services with capability-driven defaults
services = {
  audio.enable = true;           # Auto-detects PipeWire/PulseAudio
  display.enable = true;         # Auto-selects X11/Wayland
  networking.enable = true;      # WiFi, firewall auto-configured
  security.enable = true;        # Hardware-aware hardening
  ssh.enable = true;             # Secure defaults
  secrets.enable = true;         # Multi-backend encryption
};
```

### Advanced Service Configuration

```nix
services = {
  audio = {
    enable = true;
    backend = "pipewire";        # Or "pulseaudio", "coreaudio"
    quality = "high";            # Or "standard", "studio"
    bluetooth.enable = true;
  };
  
  display = {
    enable = true;
    backend = "wayland";         # Or "x11", "quartz" 
    desktop = "hyprland";        # Or "kde", "gnome", "i3"
    gaming.enable = true;
    multiMonitor.enable = true;
  };
  
  security = {
    enable = true;
    hardening.level = "high";    # Or "minimal", "standard", "paranoid"
    monitoring.enable = true;
    compliance.frameworks = [ "cis" "nist" ];
  };
  
  secrets = {
    enable = true;
    backend = "sops";            # Or "agenix", "age", "gpg"
    automation.rotation.enable = true;
    audit.logLevel = "detailed";
  };
};
```

### Device-Specific Configuration

```nix
device = {
  type = "laptop";               # Or "desktop", "server", "vm"
  capabilities = {
    hasAudio = true;
    hasGPU = true;
    hasWiFi = true;
    hasTPM = true;
    hasEncryption = true;
  };
};

# Services automatically adjust based on capabilities
```

## 🎛️ Customization

### Creating a New Host Configuration

1. **Create host directory**:
   ```bash
   mkdir -p hosts/nixos/my-machine
   ```

2. **Create configuration**:
   ```nix
   # hosts/nixos/my-machine/default.nix
   { lib, ... }: {
     imports = [
       ./hardware-configuration.nix
       ../../../modules/platform/detection.nix
       ../../../modules/platform/capabilities.nix
       ../../../modules/services/audio/interface.nix
       ../../../modules/services/display/interface.nix
       # Add other services as needed
     ];

     device = {
       type = "desktop";          # Adjust for your machine
       capabilities = {
         hasAudio = true;
         hasGPU = true;
         hasTPM = true;
         # Configure based on your hardware
       };
     };

     services = {
       audio.enable = true;
       display.enable = true;
       security.enable = true;
       # Enable services as needed
     };

     system.stateVersion = "24.05";
   }
   ```

3. **Add to flake.nix**:
   ```nix
   nixosConfigurations.my-machine = lib.nixosSystem {
     inherit system;
     modules = [ ./hosts/nixos/my-machine ];
   };
   ```

### Common Use Case Configurations

#### Gaming Workstation
```nix
device.type = "desktop";
services = {
  audio = {
    enable = true;
    quality = "high";
    bluetooth.enable = true;
  };
  display = {
    enable = true;
    backend = "x11";            # Or "wayland" for newer games
    gaming.enable = true;
    highRefreshRate.enable = true;
    multiMonitor.enable = true;
  };
  security.hardening.level = "standard";  # Balance security with performance
};
```

#### Development Server
```nix
device.type = "server";
services = {
  ssh = {
    enable = true;
    server.enable = true;
    server.hardening.level = "high";
  };
  security = {
    enable = true;
    hardening.level = "high";
    monitoring.enable = true;
  };
  secrets = {
    enable = true;
    automation.rotation.enable = true;
  };
  # Disable audio/display for headless operation
  audio.enable = false;
  display.enable = false;
};
```

#### MacBook (Darwin) - Future Support
```nix
device.type = "laptop";
services = {
  audio = {
    enable = true;
    backend = "coreaudio";
  };
  display = {
    enable = true;
    backend = "quartz";
  };
  # Darwin-specific configurations
};
```

## 🧪 Testing

The system includes comprehensive testing with 213 automated tests:

### Test Categories
- **Platform Detection** (2 tests): Verify platform identification
- **Device Capabilities** (2 tests): Test capability detection logic
- **Audio Service** (17 tests): Cross-platform audio functionality
- **Display Service** (29 tests): Graphics and desktop environments
- **Networking Service** (39 tests): Network management features
- **Security Service** (38 tests): Hardening and monitoring
- **SSH Service** (46 tests): SSH server/client management
- **Secrets Service** (44 tests): Secret storage and lifecycle

### Running Tests

```bash
# All tests
nix flake check

# Specific service tests
nix eval --impure --expr '
  let testResults = (import ./tests { 
    pkgs = import <nixpkgs> {}; 
    lib = (import <nixpkgs> {}).lib; 
  });
  in lib.all (x: x) (lib.attrValues testResults.audioResults)
'

# Test results summary
nix eval --impure --expr '
  let results = (import ./tests { 
    pkgs = import <nixpkgs> {}; 
    lib = (import <nixpkgs> {}).lib; 
  }).results;
  in {
    total = lib.length (lib.attrNames results);
    passing = lib.length (lib.filterAttrs (n: v: v) results);
  }
'
```

## 🔍 Debugging and Troubleshooting

### Capability Detection

```bash
# Show detected device capabilities
show-capabilities

# Example output:
# Device Type: laptop
# Audio: true
# GPU: true
# GUI: true
# WiFi: true
# Encryption: true
# TPM: true
```

### Service Status

```bash
# Check service implementation details
nix eval --impure --expr '
  let config = (import ./tests/lib/test-utils.nix { 
    pkgs = import <nixpkgs> {}; 
    lib = (import <nixpkgs> {}).lib; 
  }).evalConfig [ 
    ./modules/services/audio/interface.nix
    ./modules/services/audio/nixos.nix
    { device.type = "laptop"; services.audio.enable = true; }
  ];
  in config.config.services.audio._implementation
'
```

### Common Issues

1. **Module evaluation errors**: Check for circular dependencies
   ```bash
   nix eval --show-trace .#nixosConfigurations.eye-of-god.config.system.build.toplevel
   ```

2. **Assertion failures**: Review capability dependencies
   ```bash
   # Assertions are logged during evaluation
   ```

3. **Test failures**: Run specific test categories to isolate issues
   ```bash
   nix eval --impure --expr '(import ./tests { 
     pkgs = import <nixpkgs> {}; 
     lib = (import <nixpkgs> {}).lib; 
   }).secretsResults'
   ```

## 🗺️ Roadmap

### ✅ Completed (Phase 1-2.6)
- [x] Testing framework with comprehensive coverage
- [x] Platform detection and device capabilities  
- [x] Service abstraction layer foundation
- [x] Audio service abstraction (17 tests)
- [x] Display/graphics service abstraction (29 tests)
- [x] Networking service abstraction (39 tests)
- [x] Security service abstraction (38 tests)
- [x] SSH service abstraction (46 tests)
- [x] Secrets management service (44 tests)

### 🔄 In Progress (Phase 2.7)
- [ ] User home configuration service
- [ ] Advanced Home Manager integration

### ⏳ Planned (Phase 3+)
- [ ] Dynamic module loading and discovery
- [ ] Configuration profiles and feature flags
- [ ] Centralized package management
- [ ] Darwin (macOS) platform support
- [ ] Performance optimization
- [ ] Migration tools for existing configurations

## 📝 Development Guidelines

### Adding New Services

1. **Create interface module**: `modules/services/example/interface.nix`
2. **Implement platform support**: `modules/services/example/nixos.nix`
3. **Write comprehensive tests**: `tests/unit/services/example-test.nix`
4. **Update test runner**: Add to `tests/default.nix`
5. **Test thoroughly**: `nix flake check`

### Module Development Standards

- Use capability detection before enabling hardware-dependent features
- Follow existing import patterns and naming conventions
- Implement platform-specific code behind abstraction layers
- Validate configuration options with assertions
- Provide meaningful error messages for configuration failures

### Testing Requirements

- **NEVER** implement a module without corresponding tests
- **ALWAYS** run `nix flake check` before committing changes
- Write unit tests for individual module logic and options
- Write integration tests for complete system configurations
- Test failure scenarios and assertion violations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Follow development guidelines and testing requirements
4. Ensure all tests pass: `nix flake check`
5. Commit changes: `git commit -m 'feat: add amazing feature'`
6. Push to branch: `git push origin feature/amazing-feature`
7. Open a Pull Request

## 📚 Additional Resources

- [Implementation Plan](docs/architecture-redesign-implementation-plan.md) - Detailed development roadmap
- [CLAUDE.md](CLAUDE.md) - Development guidance for AI assistants
- [Nix Manual](https://nixos.org/manual/nix/stable/) - Official Nix documentation
- [NixOS Manual](https://nixos.org/manual/nixos/stable/) - NixOS configuration guide

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Zach Bedewi**

---

*Zyx - Advanced configuration management for the modern age* 🚀