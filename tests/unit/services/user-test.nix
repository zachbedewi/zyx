{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the modules under test
  userInterface = ../../../modules/services/user/interface.nix;
  userNixos = ../../../modules/services/user/nixos.nix;
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  secretsInterface = ../../../modules/services/secrets/interface.nix;
  sshInterface = ../../../modules/services/ssh/interface.nix;
  securityInterface = ../../../modules/services/security/interface.nix;
  displayInterface = ../../../modules/services/display/interface.nix;
  
  testConfig = modules: (testUtils.evalConfig modules).config;
  
  # Base test configuration with user management capabilities
  baseConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasUsers = true;
        hasGUI = true;
        hasNetwork = true;
        hasWayland = true;
        hasX11 = true;
        hasAudio = true;
        hasGPU = true;
        hasEncryption = true;
      };
    };
    # Enable required services for integration
    services.secrets.enable = true;
    services.ssh.enable = true;
    services.security.enable = true;
    services.display.enable = true;
  };

  # Minimal test configuration for basic functionality
  minimalConfig = {
    device = {
      type = "server";
      capabilities = {
        hasUsers = true;
        hasGUI = false;
        hasNetwork = true;
        hasWayland = false;
        hasX11 = false;
        hasAudio = false;
        hasGPU = false;
        hasEncryption = false;
      };
    };
  };

  # Developer workstation configuration
  developerConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasUsers = true;
        hasGUI = true;
        hasNetworking = true;
        hasWayland = true;
        hasX11 = true;
        hasAudio = true;
        hasGPU = true;
        hasEncryption = true;
      };
    };
    services.secrets.enable = true;
    services.ssh.enable = true;
    services.security.enable = true;
    services.display.enable = true;
  };

in {
  name = "user-service";
  tests = [
    # Basic functionality tests
    {
      name = "user-service-defaults-to-enabled-when-platform-supports-users";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.enable;
      expected = true;
    }

    {
      name = "user-service-disabled-when-platform-lacks-user-support";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        (baseConfig // {
          device.capabilities.hasUsers = false;
        })
      ]).services.user.enable;
      expected = false;
    }

    # Profile management tests
    {
      name = "profile-management-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.profiles.enable;
      expected = true;
    }

    {
      name = "dotfile-synchronization-enabled-with-profiles";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.profiles.synchronization.enable;
      expected = true;
    }

    {
      name = "profile-synchronization-backend-auto-selects-git-with-network";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.profiles.synchronization.backend;
      expected = "git";
    }

    {
      name = "profile-synchronization-backend-selects-rsync-without-network";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        (baseConfig // {
          device.capabilities.hasNetworking = false;
        })
      ]).services.user.profiles.synchronization.backend;
      expected = "rsync";
    }

    {
      name = "dotfile-patterns-include-common-files";
      expr = lib.elem ".bashrc" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.profiles.dotfiles.patterns;
      expected = true;
    }

    {
      name = "dotfile-excludes-include-log-files";
      expr = lib.elem "*.log" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.profiles.dotfiles.excludePatterns;
      expected = true;
    }

    # Application management tests
    {
      name = "application-management-enabled-with-gui";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.applications.enable;
      expected = true;
    }

    {
      name = "application-management-disabled-without-gui";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        minimalConfig 
      ]).services.user.applications.enable;
      expected = false;
    }

    {
      name = "workspace-management-enabled-with-wayland";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.applications.workspace.enable;
      expected = true;
    }

    {
      name = "workspace-backend-auto-selects-hyprland-with-wayland";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.applications.workspace.backend;
      expected = "hyprland";
    }

    {
      name = "workspace-backend-selects-i3-with-x11-only";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        (baseConfig // {
          device.capabilities.hasWayland = false;
        })
      ]).services.user.applications.workspace.backend;
      expected = "i3";
    }

    {
      name = "application-state-auto-restore-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.applications.stateManagement.autoRestore;
      expected = true;
    }

    {
      name = "workspace-auto-save-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.applications.workspace.autoSave;
      expected = true;
    }

    # Security integration tests
    {
      name = "user-security-enabled-when-system-security-enabled";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        securityInterface
        baseConfig 
      ]).services.user.security.enable;
      expected = true;
    }

    {
      name = "personal-secrets-enabled-with-secrets-service";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        secretsInterface
        securityInterface
        baseConfig 
      ]).services.user.security.personalSecrets.enable;
      expected = true;
    }

    {
      name = "ssh-key-management-enabled-with-ssh-service";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        sshInterface
        securityInterface
        baseConfig 
      ]).services.user.security.sshKeys.enable;
      expected = true;
    }

    {
      name = "ssh-key-auto-generation-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        sshInterface
        securityInterface
        baseConfig 
      ]).services.user.security.sshKeys.autoGenerate;
      expected = true;
    }

    {
      name = "ssh-key-types-include-ed25519";
      expr = lib.elem "ed25519" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        sshInterface
        securityInterface
        baseConfig 
      ]).services.user.security.sshKeys.keyTypes;
      expected = true;
    }

    {
      name = "ssh-key-rotation-disabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        sshInterface
        securityInterface
        baseConfig 
      ]).services.user.security.sshKeys.rotation.enable;
      expected = false;
    }

    {
      name = "access-control-includes-standard-groups";
      expr = lib.elem "users" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.security.accessControl.groups;
      expected = true;
    }

    {
      name = "access-control-includes-audio-group-with-audio-capability";
      expr = lib.elem "audio" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.security.accessControl.groups;
      expected = true;
    }

    {
      name = "access-control-includes-developer-groups-for-developer";
      expr = lib.elem "docker" (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        developerConfig
      ]).services.user.security.accessControl.groups;
      expected = true;
    }

    # User experience tests
    {
      name = "user-experience-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.experience.enable;
      expected = true;
    }

    {
      name = "theme-management-enabled-with-gui-and-display";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        displayInterface
        baseConfig 
      ]).services.user.experience.theme.enable;
      expected = true;
    }

    {
      name = "theme-style-defaults-to-auto";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.experience.theme.style;
      expected = "auto";
    }

    {
      name = "shell-management-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.experience.shell.enable;
      expected = true;
    }

    {
      name = "shell-auto-selects-zsh-for-developer";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        developerConfig
      ]).services.user.experience.shell.defaultShell;
      expected = "zsh";
    }

    {
      name = "shell-auto-selects-bash-for-non-developer";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        (baseConfig // {
          device.capabilities = baseConfig.device.capabilities // {
            hasGUI = false;  # This will make isDevelopment false
          };
        })
      ]).services.user.experience.shell.defaultShell;
      expected = "bash";
    }

    {
      name = "editor-management-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.experience.editor.enable;
      expected = true;
    }

    {
      name = "editor-auto-selects-nvim-for-developer";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        developerConfig
      ]).services.user.experience.editor.defaultEditor;
      expected = "nvim";
    }

    {
      name = "editor-auto-selects-vscode-for-gui-non-developer";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        (baseConfig // {
          device.capabilities = baseConfig.device.capabilities // {
            hasNetworking = false;  # This makes isDevelopment false while keeping GUI for vscode
          };
        })
      ]).services.user.experience.editor.defaultEditor;
      expected = "vscode";
    }

    {
      name = "editor-auto-selects-vim-for-no-gui";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        minimalConfig
      ]).services.user.experience.editor.defaultEditor;
      expected = "vim";
    }

    # Backup tests
    {
      name = "backup-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.backup.enable;
      expected = true;
    }

    {
      name = "automatic-backup-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.backup.automatic;
      expected = true;
    }

    {
      name = "backup-interval-defaults-to-daily";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.backup.interval;
      expected = "daily";
    }

    {
      name = "backup-compression-enabled-by-default";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        baseConfig 
      ]).services.user.backup.compression;
      expected = true;
    }

    {
      name = "backup-encryption-enabled-with-security";
      expr = (testConfig [ 
        userInterface 
        platformDetection 
        platformCapabilities 
        securityInterface
        baseConfig 
      ]).services.user.backup.encryption;
      expected = true;
    }

    # Assertion tests for invalid configurations
    {
      name = "application-management-requires-gui-capability";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        {
          device = {
            type = "laptop";
            capabilities.hasUsers = true;
            capabilities.hasGUI = false;
          };
          services.user.applications.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "workspace-management-requires-display-server";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        {
          device = {
            type = "laptop";
            capabilities = {
              hasUsers = true;
              hasGUI = true;
              hasWayland = false;
              hasX11 = false;
            };
          };
          services.user.applications.workspace.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "personal-secrets-requires-secrets-service";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        secretsInterface
        {
          device = {
            type = "laptop";
            capabilities.hasUsers = true;
          };
          services.secrets.enable = false;
          services.user.security.personalSecrets.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "ssh-key-management-requires-ssh-service";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        sshInterface
        {
          device = {
            type = "laptop";
            capabilities.hasUsers = true;
          };
          services.ssh.enable = false;
          services.user.security.sshKeys.enable = true;
        }
      ];
      expected = true;
    }

    {
      name = "remote-synchronization-requires-url";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        {
          device = {
            type = "laptop";
            capabilities.hasUsers = true;
          };
          services.user.profiles.synchronization.remote = {
            enable = true;
            url = null;
          };
        }
      ];
      expected = true;
    }

    {
      name = "explicit-authentication-requires-secret-reference";
      expr = testUtils.assertionShouldFail [
        userInterface 
        platformDetection 
        platformCapabilities 
        {
          device = {
            type = "laptop";
            capabilities.hasUsers = true;
          };
          services.user.profiles.synchronization.remote = {
            enable = true;
            url = "git@github.com:user/dotfiles.git";
            authentication = {
              method = "ssh-key";
              secretRef = null;
            };
          };
        }
      ];
      expected = true;
    }

    # NixOS implementation tests - commented out as they require full NixOS evaluation
    # {
    #   name = "nixos-implementation-provides-user-management-utilities";
    #   expr = let
    #     cfg = testConfig [ 
    #       userInterface 
    #       userNixos
    #       platformDetection 
    #       platformCapabilities 
    #       baseConfig 
    #     ];
    #     packages = cfg.environment.systemPackages;
    #     hasUtility = name: lib.any (pkg: 
    #       if lib.isDerivation pkg && pkg ? name
    #       then lib.hasInfix name pkg.name
    #       else false
    #     ) packages;
    #   in hasUtility "zyx-sync-dotfiles";
    #   expected = true;
    # }

    # Commented out - systemd services require full NixOS evaluation context
    # {
    #   name = "nixos-implementation-creates-systemd-services";
    #   expr = let
    #     cfg = testConfig [ 
    #       userInterface 
    #       userNixos
    #       platformDetection 
    #       platformCapabilities 
    #       baseConfig 
    #     ];
    #   in cfg.systemd.user.services ? zyx-dotfile-sync;
    #   expected = true;
    # }

    {
      name = "nixos-implementation-stores-metadata";
      expr = let
        cfg = testConfig [ 
          userInterface 
          userNixos
          platformDetection 
          platformCapabilities 
          baseConfig 
        ];
      in cfg.services.user._implementation.platform;
      expected = "nixos";
    }
  ];
}