{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the modules under test
  securityInterface = ../../../modules/services/security/interface.nix;
  securityNixos = ../../../modules/services/security/nixos.nix;
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  
  testConfig = modules: (testUtils.evalConfig modules).config;
  
  # Base test configuration
  baseConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasEncryption = true;
        hasSecureBoot = true;
        hasTPM = true;
        hasSELinux = true;
      };
    };
  };

  # Mock hardware configurations
  desktopConfig = {
    device = {
      type = "desktop";
      capabilities = {
        hasEncryption = true;
        hasSecureBoot = true;
        hasTPM = true;
        hasSELinux = true;
        hasHardwareRNG = true;
      };
    };
  };

  serverConfig = {
    device = {
      type = "server";
      capabilities = {
        hasEncryption = true;
        hasSecureBoot = true;
        hasTPM = true;
        hasSELinux = true;
        hasHardwareRNG = true;
        hasGUI = false;
      };
    };
  };

  vmConfig = {
    device = {
      type = "vm";
      capabilities = {
        hasEncryption = false;  # VMs typically don't have hardware encryption
        hasSecureBoot = false;
        hasTPM = false;
        hasSELinux = false;
        hasHardwareRNG = false;
      };
    };
  };

  # Test access control policies
  testPolicies = {
    "web-browser" = {
      program = "/usr/bin/firefox";
      profile = "web-browser";
      capabilities = [ "net_bind_service" ];
      networkAccess = true;
      filesystemAccess = [ "/home/*/Downloads" "/tmp" ];
    };
    "system-service" = {
      program = "/usr/bin/systemd";
      profile = "system-service";
      capabilities = [ "sys_admin" "net_admin" ];
      networkAccess = false;
      filesystemAccess = [ "/etc" "/var" ];
    };
  };

  # Test compliance frameworks
  cisFramework = [ "cis" ];
  nistFramework = [ "nist" ];
  multiFramework = [ "cis" "nist" "iso27001" ];

in {
  name = "security-service";
  tests = [
    # Basic functionality tests
    {
      name = "security-service-defaults-to-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.enable;
      expected = true;
    }

    {
      name = "hardening-defaults-to-enabled-when-security-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.enable;
      expected = true;
    }

    {
      name = "hardening-level-defaults-to-standard";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.level;
      expected = "standard";
    }

    # Hardening level tests
    {
      name = "minimal-hardening-level";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "minimal"; }
      ]).services.security.hardening.level;
      expected = "minimal";
    }

    {
      name = "high-hardening-level";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "high"; }
      ]).services.security.hardening.level;
      expected = "high";
    }

    {
      name = "paranoid-hardening-level";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "paranoid"; }
      ]).services.security.hardening.level;
      expected = "paranoid";
    }

    # Access control tests
    {
      name = "access-control-defaults-to-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.accessControl.enable;
      expected = true;
    }

    {
      name = "access-control-backend-defaults-to-auto";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.accessControl.backend;
      expected = "auto";
    }

    {
      name = "access-control-enforcing-defaults-to-true-for-standard";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.accessControl.enforcing;
      expected = true;
    }

    {
      name = "access-control-enforcing-false-for-minimal";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "minimal"; }
      ]).services.security.accessControl.enforcing;
      expected = false;
    }

    {
      name = "access-control-policies-configuration";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.accessControl.policies = testPolicies; }
      ]).services.security.accessControl.policies."web-browser".networkAccess;
      expected = true;
    }

    # Monitoring tests
    {
      name = "security-monitoring-defaults-to-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.monitoring.enable;
      expected = true;
    }

    {
      name = "auditd-defaults-to-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.monitoring.auditd.enable;
      expected = true;
    }

    {
      name = "intrusion-detection-enabled-for-workstation";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig  # laptop is workstation
      ]).services.security.monitoring.intrusion.enable;
      expected = true;
    }

    {
      name = "intrusion-detection-backend-defaults-to-auto";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.monitoring.intrusion.backend;
      expected = "auto";
    }

    # Encryption tests
    {
      name = "encryption-defaults-to-enabled";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.encryption.enable;
      expected = true;
    }

    {
      name = "disk-encryption-enabled-when-capable";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.encryption.diskEncryption.enable;
      expected = true;
    }

    {
      name = "secure-boot-enabled-when-capable";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.encryption.secureBoot.enable;
      expected = true;
    }

    {
      name = "tpm-enabled-when-available";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.encryption.tpm.enable;
      expected = true;
    }

    # Compliance tests
    {
      name = "compliance-disabled-by-default";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.compliance.enable;
      expected = false;
    }

    {
      name = "compliance-enabled-for-paranoid-level";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "paranoid"; }
      ]).services.security.compliance.enable;
      expected = true;
    }

    {
      name = "cis-framework-configuration";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { 
          services.security.compliance.enable = true;
          services.security.compliance.frameworks = cisFramework;
        }
      ]).services.security.compliance.frameworks;
      expected = cisFramework;
    }

    # Device type specific tests
    {
      name = "server-defaults-to-high-hardening";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        serverConfig 
      ]).services.security.hardening.level;
      expected = "high";
    }

    {
      name = "vm-disables-hardware-features";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        vmConfig 
      ]).services.security.encryption.diskEncryption.enable;
      expected = false;
    }

    # Kernel hardening tests
    {
      name = "kernel-hardening-enabled-by-default";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.kernel.enable;
      expected = true;
    }

    {
      name = "kernel-mitigations-enabled-by-default";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.kernel.mitigations;
      expected = true;
    }

    {
      name = "kernel-lockdown-enabled-for-standard";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.kernel.lockdown;
      expected = true;
    }

    {
      name = "kernel-lockdown-disabled-for-minimal";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "minimal"; }
      ]).services.security.hardening.kernel.lockdown;
      expected = false;
    }

    # Filesystem hardening tests
    {
      name = "filesystem-hardening-enabled-by-default";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.filesystem.enable;
      expected = true;
    }

    {
      name = "hidepid-enabled-for-standard";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.filesystem.hidepid;
      expected = true;
    }

    {
      name = "hidepid-disabled-for-minimal";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "minimal"; }
      ]).services.security.hardening.filesystem.hidepid;
      expected = false;
    }

    # Network hardening tests
    {
      name = "network-hardening-enabled-by-default";
      expr = (testConfig [ 
        securityInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security.hardening.network.enable;
      expected = true;
    }

    # Assertion tests (should fail)
    {
      name = "disk-encryption-requires-encryption-capability";
      expr = testUtils.assertionShouldFail [
        securityInterface
        platformDetection
        platformCapabilities
        {
          device = {
            type = "vm";
            capabilities.hasEncryption = false;
          };
          services.security.encryption.diskEncryption.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "secure-boot-requires-secure-boot-capability";
      expr = testUtils.assertionShouldFail [
        securityInterface
        platformDetection
        platformCapabilities
        {
          device = {
            type = "vm";
            capabilities.hasSecureBoot = false;
          };
          services.security.encryption.secureBoot.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "tpm-requires-tpm-capability";
      expr = testUtils.assertionShouldFail [
        securityInterface
        platformDetection
        platformCapabilities
        {
          device = {
            type = "vm";
            capabilities.hasTPM = false;
          };
          services.security.encryption.tpm.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "enforcing-mode-requires-access-control";
      expr = testUtils.assertionShouldFail [
        securityInterface
        platformDetection
        platformCapabilities
        baseConfig
        {
          services.security.accessControl.enable = false;
          services.security.accessControl.enforcing = true;
        }
      ];
      expected = true;
    }

    # Integration tests with NixOS implementation
    {
      name = "nixos-implementation-metadata";
      expr = (testConfig [ 
        securityInterface 
        securityNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.security._implementation.platform;
      expected = "nixos";
    }

    {
      name = "nixos-hardening-level-in-metadata";
      expr = (testConfig [ 
        securityInterface 
        securityNixos
        platformDetection 
        platformCapabilities 
        baseConfig
        { services.security.hardening.level = "high"; }
      ]).services.security._implementation.hardeningLevel;
      expected = "high";
    }
  ];
}