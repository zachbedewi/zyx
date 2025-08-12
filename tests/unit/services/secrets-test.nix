{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the modules under test
  secretsInterface = ../../../modules/services/secrets/interface.nix;
  secretsNixos = ../../../modules/services/secrets/nixos.nix;
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  securityInterface = ../../../modules/services/security/interface.nix;
  sshInterface = ../../../modules/services/ssh/interface.nix;
  
  testConfig = modules: (testUtils.evalConfig modules).config;
  
  # Base test configuration with encryption capabilities
  baseConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasEncryption = true;
        hasNetworking = true;
        hasGUI = true;
        hasTPM = false;
        hasHardwareRNG = false;
        hasMemoryProtection = true;
      };
    };
  };

  # Enhanced desktop configuration with security hardware
  desktopConfig = {
    device = {
      type = "desktop";
      capabilities = {
        hasEncryption = true;
        hasNetworking = true;
        hasGUI = true;
        hasTPM = true;
        hasHardwareRNG = true;
        hasMemoryProtection = true;
      };
    };
  };

  # Server configuration focused on security
  serverConfig = {
    device = {
      type = "server";
      capabilities = {
        hasEncryption = true;
        hasNetworking = true;
        hasGUI = false;
        hasTPM = true;
        hasHardwareRNG = true;
        hasMemoryProtection = true;
        isHeadless = true;
      };
    };
  };

  # VM configuration with limited capabilities
  vmConfig = {
    device = {
      type = "vm";
      capabilities = {
        hasEncryption = true;
        hasNetworking = true;
        hasGUI = false;
        hasTPM = false;
        hasHardwareRNG = false;
        hasMemoryProtection = false;
        isHeadless = true;
      };
    };
  };

  # Configuration with security service enabled
  securityEnabledConfig = baseConfig // {
    services.security = {
      enable = true;
      hardening = {
        enable = true;
        level = "standard";
      };
      monitoring.enable = true;
    };
  };

  # Configuration with SSH service enabled
  sshEnabledConfig = baseConfig // {
    services.ssh = {
      enable = true;
      server.enable = true;
      keys.enable = true;
    };
  };

in {
  name = "secrets-service";
  tests = [
    # Basic functionality tests
    {
      name = "secrets-service-defaults-enabled-with-encryption";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
      ]).services.secrets.enable;
      expected = true;
    }

    {
      name = "secrets-service-disabled-without-encryption";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        (baseConfig // {
          device.capabilities.hasEncryption = false;
        })
      ]).services.secrets.enable;
      expected = false;
    }

    {
      name = "secrets-backend-auto-selects-sops-on-nixos";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.backend;
      expected = "sops";
    }

    # Backend selection tests
    {
      name = "secrets-backend-respects-manual-selection";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            backend = "age";
          };
        }
      ]).services.secrets.backend;
      expected = "age";
    }

    # Storage configuration tests
    {
      name = "secrets-storage-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.enable;
      expected = true;
    }

    {
      name = "secrets-encryption-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.enable;
      expected = true;
    }

    {
      name = "secrets-encryption-algorithm-aes256gcm-with-tpm";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        desktopConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.algorithm;
      expected = "aes256gcm";
    }

    {
      name = "secrets-encryption-algorithm-age-without-tpm";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.algorithm;
      expected = "age";
    }

    # Secret types tests
    {
      name = "ssh-keys-enabled-when-ssh-service-present";
      expr = (testConfig [ 
        secretsInterface 
        sshInterface
        platformDetection 
        platformCapabilities
        sshEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets.types.sshKeys.enable;
      expected = true;
    }

    {
      name = "ssh-keys-disabled-when-ssh-service-absent";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.types.sshKeys.enable;
      expected = false;
    }

    {
      name = "api-tokens-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.types.apiTokens.enable;
      expected = true;
    }

    # Password complexity tests
    {
      name = "password-complexity-standard-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.types.passwords.complexity;
      expected = "standard";
    }

    {
      name = "password-complexity-inherits-from-security-service";
      expr = (testConfig [ 
        secretsInterface 
        securityInterface
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets.enable = true;
          services.security = {
            enable = true;
            hardening = {
              enable = true;
              level = "high";
            };
            monitoring.enable = true;
          };
        }
      ]).services.secrets.types.passwords.complexity;
      expected = "high";
    }

    # Access control tests
    {
      name = "default-access-groups-include-wheel";
      expr = lib.elem "wheel" (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.access.groups;
      expected = true;
    }

    # Automation tests
    {
      name = "automation-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.automation.enable;
      expected = true;
    }

    {
      name = "provisioning-enabled-with-automation";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.automation.provisioning.enable;
      expected = true;
    }

    {
      name = "rotation-disabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.automation.rotation.enable;
      expected = false;
    }

    {
      name = "lifecycle-management-enabled-with-automation";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.automation.lifecycle.enable;
      expected = true;
    }

    # Audit tests
    {
      name = "audit-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.audit.enable;
      expected = true;
    }

    {
      name = "audit-level-detailed-with-security-monitoring";
      expr = (testConfig [ 
        secretsInterface 
        securityInterface
        platformDetection 
        platformCapabilities
        securityEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets.audit.logLevel;
      expected = "detailed";
    }

    {
      name = "audit-level-standard-without-security-monitoring";
      expr = (testConfig [ 
        secretsInterface 
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.audit.logLevel;
      expected = "standard";
    }

    # Integration tests
    {
      name = "ssh-integration-enabled-with-ssh-service";
      expr = (testConfig [ 
        secretsInterface 
        sshInterface
        platformDetection 
        platformCapabilities
        sshEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets.integration.ssh.enable;
      expected = true;
    }

    {
      name = "security-integration-enabled-with-security-service";
      expr = (testConfig [ 
        secretsInterface 
        securityInterface
        platformDetection 
        platformCapabilities
        securityEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets.integration.security.enable;
      expected = true;
    }

    {
      name = "hardening-level-inherited-from-security-service";
      expr = (testConfig [ 
        secretsInterface 
        securityInterface
        platformDetection 
        platformCapabilities
        securityEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets.integration.security.hardeningLevel;
      expected = "standard";
    }

    # Assertion tests - these should fail
    {
      name = "assertion-fails-without-encryption-capability";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        (baseConfig // {
          device.capabilities.hasEncryption = false;
        })
        { services.secrets.enable = true; }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-without-access-users-or-groups";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            access = {
              users = [];
              groups = [];
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-backup-without-location";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            storage.backup = {
              enable = true;
              location = null;
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-rotation-without-automation";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            automation = {
              enable = false;
              rotation.enable = true;
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-ssh-keys-without-ssh-service";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            types.sshKeys.enable = true;
          };
        }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-tamper-protection-without-audit";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            audit = {
              enable = false;
              tamperProtection = true;
            };
          };
        }
      ];
      expected = true;
    }

    {
      name = "assertion-fails-encryption-without-storage";
      expr = testUtils.assertionShouldFail [
        secretsInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            storage = {
              enable = false;
              encryption.enable = true;
            };
          };
        }
      ];
      expected = true;
    }

    # NixOS implementation tests
    {
      name = "nixos-implementation-platform-is-nixos";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets._implementation.platform;
      expected = "nixos";
    }

    {
      name = "nixos-implementation-backend-matches-config";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            backend = "age";
          };
        }
      ]).services.secrets._implementation.backend;
      expected = "age";
    }

    {
      name = "nixos-implementation-encryption-config-present";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets._implementation.encryptionConfig.algorithm;
      expected = "age";
    }

    {
      name = "nixos-implementation-services-enabled-status";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets._implementation.servicesEnabled.storage;
      expected = true;
    }

    {
      name = "nixos-implementation-ssh-integration-status";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        sshInterface
        platformDetection 
        platformCapabilities
        sshEnabledConfig
        { services.secrets.enable = true; }
      ]).services.secrets._implementation.integrations.ssh;
      expected = true;
    }

    # Device profile tests
    {
      name = "desktop-profile-uses-aes256gcm-with-tpm";
      expr = (testConfig [ 
        secretsInterface
        platformDetection 
        platformCapabilities
        desktopConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.algorithm;
      expected = "aes256gcm";
    }

    {
      name = "server-profile-enables-audit-by-default";
      expr = (testConfig [ 
        secretsInterface
        platformDetection 
        platformCapabilities
        serverConfig
        { services.secrets.enable = true; }
      ]).services.secrets.audit.enable;
      expected = true;
    }

    {
      name = "vm-profile-uses-basic-encryption";
      expr = (testConfig [ 
        secretsInterface
        platformDetection 
        platformCapabilities
        vmConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.algorithm;
      expected = "age";
    }

    # Memory protection tests
    {
      name = "memory-protection-enabled-by-default";
      expr = (testConfig [ 
        secretsInterface
        platformDetection 
        platformCapabilities
        baseConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.memoryProtection;
      expected = true;
    }

    {
      name = "memory-protection-disabled-on-vm-without-capability";
      expr = (testConfig [ 
        secretsInterface
        platformDetection 
        platformCapabilities
        vmConfig
        { services.secrets.enable = true; }
      ]).services.secrets.storage.encryption.memoryProtection;
      expected = false;
    }

    # Backend-specific configuration tests
    {
      name = "sops-backend-config-includes-age-keys";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            backend = "sops";
          };
        }
      ]).services.secrets._implementation.backendConfig.configPath;
      expected = "/etc/sops/age/keys.txt";
    }

    {
      name = "age-backend-config-includes-key-path";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            backend = "age";
          };
        }
      ]).services.secrets._implementation.backendConfig.keyPath;
      expected = "/var/lib/secrets/.age/key.txt";
    }

    {
      name = "gpg-backend-config-includes-gnupg-home";
      expr = (testConfig [ 
        secretsInterface
        secretsNixos
        platformDetection 
        platformCapabilities
        baseConfig
        { 
          services.secrets = {
            enable = true;
            backend = "gpg";
          };
        }
      ]).services.secrets._implementation.backendConfig.gnupgHome;
      expected = "/var/lib/secrets/.gnupg";
    }
  ];
}