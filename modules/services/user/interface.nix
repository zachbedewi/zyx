{ lib, config, pkgs, ... }:

{
  options.services.user = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable advanced user environment management services";
      default = config.device.capabilities.hasUsers;
    };

    profiles = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable user profile management";
        default = config.services.user.enable;
      };

      synchronization = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable dotfile and configuration synchronization";
          default = config.services.user.profiles.enable;
        };

        backend = lib.mkOption {
          type = lib.types.enum [ "git" "rsync" "cloud" "none" "auto" ];
          description = "Synchronization backend for user profiles";
          default = "auto";
        };

        remote = {
          enable = lib.mkOption {
            type = lib.types.bool;
            description = "Enable remote profile synchronization";
            default = false;
          };

          url = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            description = "Remote synchronization URL (git repo, rsync destination, etc.)";
            default = null;
          };

          authentication = {
            method = lib.mkOption {
              type = lib.types.enum [ "ssh-key" "password" "token" "auto" ];
              description = "Authentication method for remote synchronization";
              default = "auto";
            };

            secretRef = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Reference to authentication secret";
              default = null;
            };
          };
        };
      };

      dotfiles = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable dotfile management";
          default = config.services.user.profiles.enable;
        };

        location = lib.mkOption {
          type = lib.types.str;
          description = "Local dotfiles directory";
          default = "~/.config";
        };

        patterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "File patterns to include in dotfile management";
          default = [ ".bashrc" ".zshrc" ".vimrc" ".gitconfig" ".ssh/config" ];
        };

        excludePatterns = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "File patterns to exclude from dotfile management";
          default = [ "*.log" "*.tmp" "cache/*" ".DS_Store" ];
        };
      };
    };

    applications = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable application state management";
        default = config.services.user.enable && config.device.capabilities.hasGUI;
      };

      stateManagement = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable application state preservation";
          default = config.services.user.applications.enable;
        };

        autoRestore = lib.mkOption {
          type = lib.types.bool;
          description = "Automatically restore application state on login";
          default = true;
        };

        applications = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Applications to manage state for";
          default = [ "firefox" "chromium" "vscode" "terminal" ];
        };
      };

      workspace = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable workspace management";
          default = config.services.user.applications.enable && config.device.capabilities.hasWayland;
        };

        autoSave = lib.mkOption {
          type = lib.types.bool;
          description = "Automatically save workspace layouts";
          default = true;
        };

        restoreOnLogin = lib.mkOption {
          type = lib.types.bool;
          description = "Restore workspace layout on login";
          default = true;
        };

        backend = lib.mkOption {
          type = lib.types.enum [ "hyprland" "sway" "i3" "kde" "gnome" "auto" ];
          description = "Workspace management backend";
          default = "auto";
        };
      };
    };

    security = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable user-specific security integration";
        default = config.services.user.enable && config.services.security.enable;
      };

      personalSecrets = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable personal secrets management";
          default = config.services.user.security.enable && config.services.secrets.enable;
        };

        location = lib.mkOption {
          type = lib.types.str;
          description = "Personal secrets storage location";
          default = "~/.local/share/secrets";
        };

        categories = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Categories of personal secrets to manage";
          default = [ "ssh-keys" "api-tokens" "passwords" "certificates" ];
        };
      };

      sshKeys = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable personal SSH key management";
          default = config.services.user.security.enable && config.services.ssh.enable;
        };

        autoGenerate = lib.mkOption {
          type = lib.types.bool;
          description = "Automatically generate SSH keys if missing";
          default = true;
        };

        keyTypes = lib.mkOption {
          type = lib.types.listOf (lib.types.enum [ "ed25519" "rsa" "ecdsa" ]);
          description = "SSH key types to generate and manage";
          default = [ "ed25519" "rsa" ];
        };

        rotation = {
          enable = lib.mkOption {
            type = lib.types.bool;
            description = "Enable automatic SSH key rotation";
            default = false;
          };

          interval = lib.mkOption {
            type = lib.types.str;
            description = "SSH key rotation interval";
            default = "90d";
          };
        };
      };

      accessControl = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable user access control management";
          default = config.services.user.security.enable;
        };

        groups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Additional user groups for this user";
          default = [ ];
        };

        capabilities = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Additional capabilities for this user";
          default = [ ];
        };
      };
    };

    experience = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable cross-platform user experience unification";
        default = config.services.user.enable;
      };

      theme = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable unified theme management";
          default = config.services.user.experience.enable && config.device.capabilities.hasGUI;
        };

        style = lib.mkOption {
          type = lib.types.enum [ "light" "dark" "auto" "system" ];
          description = "Preferred theme style";
          default = "auto";
        };

        colorScheme = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Custom color scheme name";
          default = null;
        };

        fontFamily = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Preferred font family";
          default = null;
        };
      };

      shell = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable unified shell configuration";
          default = config.services.user.experience.enable;
        };

        defaultShell = lib.mkOption {
          type = lib.types.enum [ "bash" "zsh" "fish" "auto" ];
          description = "Default shell for user";
          default = "auto";
        };

        features = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Shell features to enable";
          default = [ "completion" "history" "aliases" "functions" ];
        };
      };

      editor = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable unified editor configuration";
          default = config.services.user.experience.enable;
        };

        defaultEditor = lib.mkOption {
          type = lib.types.enum [ "vim" "nvim" "emacs" "vscode" "nano" "auto" ];
          description = "Default editor for user";
          default = "auto";
        };

        features = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Editor features to enable";
          default = [ "syntax-highlighting" "auto-completion" "git-integration" ];
        };
      };
    };

    backup = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable user configuration backup";
        default = config.services.user.enable;
      };

      automatic = lib.mkOption {
        type = lib.types.bool;
        description = "Enable automatic backup";
        default = config.services.user.backup.enable;
      };

      interval = lib.mkOption {
        type = lib.types.str;
        description = "Backup interval";
        default = "daily";
      };

      retention = lib.mkOption {
        type = lib.types.str;
        description = "Backup retention period";
        default = "30d";
      };

      destination = {
        local = lib.mkOption {
          type = lib.types.str;
          description = "Local backup destination";
          default = "~/.local/share/backups";
        };

        remote = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Remote backup destination";
          default = null;
        };
      };

      compression = lib.mkOption {
        type = lib.types.bool;
        description = "Enable backup compression";
        default = true;
      };

      encryption = lib.mkOption {
        type = lib.types.bool;
        description = "Enable backup encryption";
        default = config.services.user.security.enable;
      };
    };

    # Internal implementation details
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific user management implementation";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.user.enable {
    # Capability assertions
    assertions = [
      {
        assertion = config.device.capabilities.hasUsers;
        message = "User service requires user management capability";
      }
      {
        assertion = 
          config.services.user.applications.enable -> 
          config.device.capabilities.hasGUI;
        message = "Application management requires GUI capability";
      }
      {
        assertion = 
          config.services.user.applications.workspace.enable -> 
          (config.device.capabilities.hasWayland || config.device.capabilities.hasX11);
        message = "Workspace management requires display server capability";
      }
      {
        assertion = 
          config.services.user.security.personalSecrets.enable -> 
          config.services.secrets.enable;
        message = "Personal secrets management requires system secrets service";
      }
      {
        assertion = 
          config.services.user.security.sshKeys.enable -> 
          config.services.ssh.enable;
        message = "SSH key management requires system SSH service";
      }
      {
        assertion = 
          config.services.user.profiles.synchronization.remote.enable -> 
          (config.services.user.profiles.synchronization.remote.url != null);
        message = "Remote synchronization requires a URL to be configured";
      }
      {
        assertion = 
          (config.services.user.profiles.synchronization.remote.authentication.method != "auto") -> 
          (config.services.user.profiles.synchronization.remote.authentication.secretRef != null);
        message = "Explicit authentication method requires a secret reference";
      }
    ];

    # Auto-select backends based on platform capabilities
    services.user = {
      profiles.synchronization.backend = lib.mkDefault (
        if config.device.capabilities.hasNetworking then "git"
        else "rsync"
      );

      applications.workspace.backend = lib.mkDefault (
        if config.device.capabilities.hasWayland then "hyprland"
        else if config.device.capabilities.hasX11 then "i3"
        else "none"
      );

      experience.shell.defaultShell = lib.mkDefault (
        if config.device.profiles.isDevelopment then "zsh"
        else "bash"
      );

      experience.editor.defaultEditor = lib.mkDefault (
        if config.device.profiles.isDevelopment then "nvim"
        else if config.device.capabilities.hasGUI then "vscode"
        else "vim"
      );

      security.accessControl.groups = lib.mkDefault (
        [ "users" ] ++
        lib.optionals config.device.capabilities.hasAudio [ "audio" ] ++
        lib.optionals config.device.capabilities.hasGPU [ "video" ] ++
        lib.optionals config.device.capabilities.hasNetworking [ "networkmanager" ] ++
        lib.optionals config.device.profiles.isDevelopment [ "docker" "wheel" ]
      );
    };

    # Auto-enable features based on capabilities and other services
    services.user.security.personalSecrets.enable = lib.mkDefault (
      config.services.user.security.enable && 
      config.services.secrets.enable
    );

    services.user.security.sshKeys.enable = lib.mkDefault (
      config.services.user.security.enable && 
      config.services.ssh.enable
    );

    services.user.experience.theme.enable = lib.mkDefault (
      config.services.user.experience.enable && 
      config.device.capabilities.hasGUI &&
      config.services.display.enable
    );
  };
}