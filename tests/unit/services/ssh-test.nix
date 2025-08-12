{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the modules under test
  sshInterface = ../../../modules/services/ssh/interface.nix;
  sshNixos = ../../../modules/services/ssh/nixos.nix;
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  securityInterface = ../../../modules/services/security/interface.nix;
  
  testConfig = modules: (testUtils.evalConfig modules).config;
  
  # Base test configuration
  baseConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasNetworking = true;
        hasGUI = true;
        hasWifi = true;
        hasEncryption = true;
      };
    };
  };

  # Mock hardware configurations
  desktopConfig = {
    device = {
      type = "desktop";
      capabilities = {
        hasNetworking = true;
        hasGUI = true;
        hasEncryption = true;
        hasHardwareRNG = true;
      };
    };
  };

  serverConfig = {
    device = {
      type = "server";
      capabilities = {
        hasNetworking = true;
        hasGUI = false;
        hasEncryption = true;
        hasHardwareRNG = true;
        isHeadless = true;
      };
    };
  };

  noNetworkConfig = {
    device = {
      type = "vm";
      capabilities = {
        hasNetworking = false;
        hasGUI = false;
      };
    };
  };

in {
  name = "ssh-service";
  tests = [
    
    # Basic SSH Service Tests
    {
      name = "ssh-service-enables-by-default-with-networking";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.enable;
      expected = true;
    }

    {
      name = "ssh-service-disabled-without-networking";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        noNetworkConfig 
      ]).services.ssh.enable;
      expected = false;
    }

    {
      name = "ssh-client-enabled-by-default-when-ssh-enabled";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.enable;
      expected = true;
    }

    {
      name = "ssh-server-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.server.enable;
      expected = false;
    }

    # SSH Server Configuration Tests
    {
      name = "ssh-server-default-port-22";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.server.port;
      expected = 22;
    }

    {
      name = "ssh-server-hardening-enabled-when-server-enabled";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.enable = true; }
      ]).services.ssh.server.hardening.enable;
      expected = true;
    }

    {
      name = "ssh-server-default-hardening-level-standard";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.enable = true; }
      ]).services.ssh.server.hardening.level;
      expected = "standard";
    }

    {
      name = "ssh-server-root-login-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.server.hardening.allowRootLogin;
      expected = false;
    }

    {
      name = "ssh-server-password-auth-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.server.hardening.passwordAuthentication;
      expected = false;
    }

    {
      name = "ssh-server-x11-forwarding-enabled-with-gui";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.server.hardening.x11Forwarding;
      expected = true;
    }

    {
      name = "ssh-server-x11-forwarding-disabled-on-server";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        serverConfig 
      ]).services.ssh.server.hardening.x11Forwarding;
      expected = false;
    }

    {
      name = "ssh-server-x11-forwarding-disabled-with-paranoid-hardening";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.hardening.level = "paranoid"; }
      ]).services.ssh.server.hardening.x11Forwarding;
      expected = false;
    }

    # SSH Client Configuration Tests
    {
      name = "ssh-client-compression-enabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.compression;
      expected = true;
    }

    {
      name = "ssh-client-control-master-auto-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.controlMaster;
      expected = "auto";
    }

    {
      name = "ssh-client-hash-known-hosts-enabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.hashKnownHosts;
      expected = true;
    }

    {
      name = "ssh-client-strict-host-key-checking-ask-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.strictHostKeyChecking;
      expected = "ask";
    }

    # SSH Key Management Tests
    {
      name = "ssh-keys-enabled-when-ssh-enabled";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.keys.enable;
      expected = true;
    }

    {
      name = "ssh-keys-auto-generate-enabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.keys.autoGenerate;
      expected = true;
    }

    {
      name = "ssh-keys-default-type-ed25519";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.keys.keyTypes;
      expected = [ "ed25519" ];
    }

    {
      name = "ssh-keys-rotation-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.keys.rotation.enable;
      expected = false;
    }

    {
      name = "ssh-keys-backup-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.keys.backup;
      expected = false;
    }

    # SSH Agent Tests
    {
      name = "ssh-agent-enabled-with-gui";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.agent.enable;
      expected = true;
    }

    {
      name = "ssh-agent-disabled-without-gui";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        serverConfig 
      ]).services.ssh.agent.enable;
      expected = false;
    }

    # SSH Monitoring Tests
    {
      name = "ssh-monitoring-disabled-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.monitoring.enable;
      expected = false;
    }

    {
      name = "ssh-monitoring-enabled-with-server-and-security";
      expr = (testConfig [ 
        sshInterface 
        securityInterface
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.server.enable = true;
          services.security.monitoring.enable = true;
        }
      ]).services.ssh.monitoring.enable;
      expected = true;
    }

    {
      name = "ssh-monitoring-default-log-level-info";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.monitoring.logLevel;
      expected = "INFO";
    }

    # Hardening Level Integration Tests
    {
      name = "ssh-hardening-follows-security-level-minimal";
      expr = (testConfig [ 
        sshInterface 
        securityInterface
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.server.enable = true;
          services.security.hardening.level = "minimal";
        }
      ]).services.ssh.server.hardening.level;
      expected = "standard";
    }

    {
      name = "ssh-hardening-follows-security-level-standard";
      expr = (testConfig [ 
        sshInterface 
        securityInterface
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.server.enable = true;
          services.security.hardening.level = "standard";
        }
      ]).services.ssh.server.hardening.level;
      expected = "standard";
    }

    {
      name = "ssh-hardening-follows-security-level-high";
      expr = (testConfig [ 
        sshInterface 
        securityInterface
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.server.enable = true;
          services.security.hardening.level = "high";
        }
      ]).services.ssh.server.hardening.level;
      expected = "high";
    }

    {
      name = "ssh-hardening-follows-security-level-paranoid";
      expr = (testConfig [ 
        sshInterface 
        securityInterface
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.server.enable = true;
          services.security.hardening.level = "paranoid";
        }
      ]).services.ssh.server.hardening.level;
      expected = "paranoid";
    }

    {
      name = "ssh-keys-paranoid-only-ed25519";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.hardening.level = "paranoid"; }
      ]).services.ssh.keys.keyTypes;
      expected = [ "ed25519" ];
    }

    {
      name = "ssh-keys-high-ed25519-and-rsa";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.hardening.level = "high"; }
      ]).services.ssh.keys.keyTypes;
      expected = [ "ed25519" "rsa" ];
    }

    {
      name = "ssh-keys-standard-all-types";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.hardening.level = "standard"; }
      ]).services.ssh.keys.keyTypes;
      expected = [ "ed25519" "rsa" "ecdsa" ];
    }

    # Assertion Tests
    {
      name = "ssh-requires-networking-capability";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        noNetworkConfig
        { services.ssh.enable = true; }
      ];
      expected = true;
    }

    {
      name = "ssh-server-requires-allowed-users-or-groups";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.ssh.server.enable = true;
          services.ssh.server.allowedUsers = [];
          services.ssh.server.allowedGroups = [];
        }
      ];
      expected = true;
    }

    {
      name = "ssh-password-auth-not-allowed-with-high-hardening";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.ssh.server.enable = true;
          services.ssh.server.hardening.level = "high";
          services.ssh.server.hardening.passwordAuthentication = true;
        }
      ];
      expected = true;
    }

    {
      name = "ssh-key-rotation-requires-key-management";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.ssh.keys.enable = false;
          services.ssh.keys.rotation.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "ssh-agent-requires-client";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.ssh.client.enable = false;
          services.ssh.agent.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "ssh-monitoring-requires-server";
      expr = testUtils.assertionShouldFail [
        sshInterface
        platformDetection
        platformCapabilities
        baseConfig
        { 
          services.ssh.server.enable = false;
          services.ssh.monitoring.enable = true;
        }
      ];
      expected = true;
    }

    # NixOS Implementation Tests
    {
      name = "nixos-ssh-server-configuration-applied";
      expr = (testConfig [ 
        sshInterface 
        sshNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.enable = true; }
      ]).services.openssh.enable;
      expected = true;
    }

    {
      name = "nixos-ssh-client-configuration-applied";
      expr = (testConfig [ 
        sshInterface 
        sshNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).programs.ssh.enable;
      expected = true;
    }

    {
      name = "nixos-ssh-agent-configuration-applied";
      expr = (testConfig [ 
        sshInterface 
        sshNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).programs.ssh.startAgent;
      expected = true;
    }

    {
      name = "nixos-firewall-ssh-port-opened";
      expr = lib.elem 22 (testConfig [ 
        sshInterface 
        sshNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
        { services.ssh.server.enable = true; }
      ]).networking.firewall.allowedTCPPorts;
      expected = true;
    }

    {
      name = "nixos-implementation-metadata-populated";
      expr = (testConfig [ 
        sshInterface 
        sshNixos
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh._implementation.platform;
      expected = "nixos";
    }

    # SSH Profile Tests
    {
      name = "ssh-client-profiles-empty-by-default";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.ssh.client.profiles;
      expected = {};
    }

    {
      name = "ssh-client-profile-configuration";
      expr = (testConfig [ 
        sshInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
        { 
          services.ssh.client.profiles.myserver = {
            hostname = "server.example.com";
            user = "myuser";
            port = 2222;
            identityFile = "~/.ssh/id_ed25519";
          };
        }
      ]).services.ssh.client.profiles.myserver.hostname;
      expected = "server.example.com";
    }

  ];
}