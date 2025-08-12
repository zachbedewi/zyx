{ lib, config, pkgs, ... }:

{
  options.services.secrets = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable secrets management services";
      default = config.device.capabilities.hasEncryption;
    };

    backend = lib.mkOption {
      type = lib.types.enum [ "sops" "agenix" "age" "gpg" "pass" "vault" "auto" ];
      description = "Secrets management backend to use";
      default = "auto";
    };

    storage = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable secure secret storage";
        default = config.services.secrets.enable;
      };

      location = lib.mkOption {
        type = lib.types.str;
        description = "Primary secrets storage location";
        default = "/var/lib/secrets";
      };

      encryption = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable encryption for stored secrets";
          default = true;
        };

        algorithm = lib.mkOption {
          type = lib.types.enum [ "age" "gpg" "chacha20poly1305" "aes256gcm" ];
          description = "Encryption algorithm for secrets";
          default = "age";
        };

        keyDerivation = lib.mkOption {
          type = lib.types.enum [ "pbkdf2" "scrypt" "argon2" ];
          description = "Key derivation function";
          default = "argon2";
        };

        memoryProtection = lib.mkOption {
          type = lib.types.bool;
          description = "Enable memory protection for decrypted secrets";
          default = true;
        };
      };

      backup = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable automatic secret backup";
          default = false;
        };

        location = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          description = "Backup storage location";
          default = null;
        };

        interval = lib.mkOption {
          type = lib.types.str;
          description = "Backup interval (systemd time format)";
          default = "daily";
        };

        retention = lib.mkOption {
          type = lib.types.int;
          description = "Number of backup copies to retain";
          default = 7;
        };
      };
    };

    types = {
      sshKeys = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Manage SSH keys as secrets";
          default = config.services.secrets.enable && config.services.ssh.enable or false;
        };

        autoProvision = lib.mkOption {
          type = lib.types.bool;
          description = "Automatically provision SSH keys to services";
          default = true;
        };
      };

      apiTokens = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Manage API tokens and service credentials";
          default = config.services.secrets.enable;
        };

        rotationInterval = lib.mkOption {
          type = lib.types.str;
          description = "API token rotation interval";
          default = "30d";
        };
      };

      certificates = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Manage TLS certificates and PKI materials";
          default = config.services.secrets.enable;
        };

        autoRenewal = lib.mkOption {
          type = lib.types.bool;
          description = "Enable automatic certificate renewal";
          default = true;
        };

        expiryWarning = lib.mkOption {
          type = lib.types.str;
          description = "Certificate expiry warning threshold";
          default = "30d";
        };
      };

      passwords = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Manage user and service passwords";
          default = config.services.secrets.enable;
        };

        complexity = lib.mkOption {
          type = lib.types.enum [ "basic" "standard" "high" "paranoid" ];
          description = "Password complexity requirements";
          default = "standard";
        };

        length = lib.mkOption {
          type = lib.types.int;
          description = "Minimum password length";
          default = 16;
        };

        rotationInterval = lib.mkOption {
          type = lib.types.str;
          description = "Password rotation interval";
          default = "90d";
        };
      };

      environmentVariables = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Manage secret environment variables";
          default = config.services.secrets.enable;
        };

        scope = lib.mkOption {
          type = lib.types.enum [ "system" "user" "service" ];
          description = "Scope for secret environment variables";
          default = "service";
        };
      };
    };

    access = {
      users = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Users with access to secrets management";
        default = [];
      };

      groups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Groups with access to secrets management";
        default = [ "wheel" ];
      };

      services = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Services with access to specific secrets";
        default = [];
      };

      policies = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            users = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Users with access to this secret";
              default = [];
            };

            groups = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Groups with access to this secret";
              default = [];
            };

            services = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Services with access to this secret";
              default = [];
            };

            permissions = lib.mkOption {
              type = lib.types.listOf (lib.types.enum [ "read" "write" "delete" "rotate" ]);
              description = "Permissions for this secret";
              default = [ "read" ];
            };

            timeRestrictions = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Time-based access restrictions";
              default = null;
            };
          };
        });
        description = "Access control policies for specific secrets";
        default = {};
      };
    };

    automation = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable automated secret management";
        default = config.services.secrets.enable;
      };

      provisioning = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable automatic secret provisioning";
          default = config.services.secrets.automation.enable;
        };

        onDemand = lib.mkOption {
          type = lib.types.bool;
          description = "Generate secrets on-demand when missing";
          default = true;
        };

        templates = lib.mkOption {
          type = lib.types.attrsOf (lib.types.submodule {
            options = {
              type = lib.mkOption {
                type = lib.types.enum [ "password" "apiKey" "certificate" "sshKey" ];
                description = "Type of secret to generate";
              };

              length = lib.mkOption {
                type = lib.types.nullOr lib.types.int;
                description = "Length for generated secrets";
                default = null;
              };

              complexity = lib.mkOption {
                type = lib.types.nullOr (lib.types.enum [ "basic" "standard" "high" "paranoid" ]);
                description = "Complexity level for generated secrets";
                default = null;
              };

              template = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                description = "Template for secret generation";
                default = null;
              };
            };
          });
          description = "Secret generation templates";
          default = {};
        };
      };

      rotation = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable automatic secret rotation";
          default = false;
        };

        schedule = lib.mkOption {
          type = lib.types.str;
          description = "Secret rotation schedule";
          default = "monthly";
        };

        notifyBefore = lib.mkOption {
          type = lib.types.str;
          description = "Notification time before rotation";
          default = "7d";
        };

        gracePeriod = lib.mkOption {
          type = lib.types.str;
          description = "Grace period for old secrets after rotation";
          default = "24h";
        };
      };

      lifecycle = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable secret lifecycle management";
          default = config.services.secrets.automation.enable;
        };

        maxAge = lib.mkOption {
          type = lib.types.str;
          description = "Maximum age for secrets before rotation";
          default = "1y";
        };

        warnAge = lib.mkOption {
          type = lib.types.str;
          description = "Age at which to warn about secret expiry";
          default = "30d";
        };

        archiveExpired = lib.mkOption {
          type = lib.types.bool;
          description = "Archive expired secrets instead of deleting";
          default = true;
        };
      };
    };

    audit = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable secrets audit logging";
        default = config.services.secrets.enable;
      };

      logLevel = lib.mkOption {
        type = lib.types.enum [ "minimal" "standard" "detailed" "paranoid" ];
        description = "Audit logging level";
        default = "standard";
      };

      logAccess = lib.mkOption {
        type = lib.types.bool;
        description = "Log secret access events";
        default = config.services.secrets.audit.enable;
      };

      logModification = lib.mkOption {
        type = lib.types.bool;
        description = "Log secret modification events";
        default = config.services.secrets.audit.enable;
      };

      logRotation = lib.mkOption {
        type = lib.types.bool;
        description = "Log secret rotation events";
        default = config.services.secrets.audit.enable;
      };

      logFailures = lib.mkOption {
        type = lib.types.bool;
        description = "Log secret access failures";
        default = config.services.secrets.audit.enable;
      };

      retention = lib.mkOption {
        type = lib.types.str;
        description = "Audit log retention period";
        default = "1y";
      };

      tamperProtection = lib.mkOption {
        type = lib.types.bool;
        description = "Enable audit log tamper protection";
        default = config.services.secrets.audit.logLevel == "paranoid";
      };
    };

    integration = {
      ssh = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable SSH service integration";
          default = config.services.secrets.enable && config.services.ssh.enable or false;
        };

        keyProvisioning = lib.mkOption {
          type = lib.types.bool;
          description = "Automatically provision SSH keys from secrets";
          default = config.services.secrets.integration.ssh.enable;
        };
      };

      security = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable security service integration";
          default = config.services.secrets.enable && config.services.security.enable or false;
        };

        hardeningLevel = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "minimal" "standard" "high" "paranoid" ]);
          description = "Inherit hardening level from security service";
          default = null;
        };
      };

      networking = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable networking service integration";
          default = config.services.secrets.enable && config.services.networking.enable or false;
        };

        vpnCredentials = lib.mkOption {
          type = lib.types.bool;
          description = "Manage VPN credentials through secrets service";
          default = config.services.secrets.integration.networking.enable;
        };
      };
    };

    # Internal implementation details
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific secrets implementation";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.secrets.enable {
    # Capability assertions
    assertions = [
      {
        assertion = config.device.capabilities.hasEncryption || !config.services.secrets.enable;
        message = "Secrets service requires encryption capability";
      }
      {
        assertion = !config.services.secrets.storage.encryption.enable || config.services.secrets.storage.enable;
        message = "Secret storage encryption requires storage to be enabled";
      }
      {
        assertion = !config.services.secrets.storage.backup.enable || config.services.secrets.storage.backup.location != null;
        message = "Secret backup requires backup location to be specified";
      }
      {
        assertion = !config.services.secrets.automation.rotation.enable || config.services.secrets.automation.enable;
        message = "Secret rotation requires automation to be enabled";
      }
      {
        assertion = !config.services.secrets.types.sshKeys.enable || config.services.ssh.enable or false;
        message = "SSH key management requires SSH service to be enabled";
      }
      {
        assertion = config.services.secrets.access.users != [] || config.services.secrets.access.groups != [];
        message = "Secrets service requires at least one user or group to have access";
      }
      {
        assertion = !config.services.secrets.audit.tamperProtection || config.services.secrets.audit.enable;
        message = "Audit tamper protection requires audit logging to be enabled";
      }
    ];

    # Auto-select backend based on platform capabilities and available tools
    services.secrets.backend = lib.mkDefault (
      if config.services.secrets.backend == "auto" then
        if config.device.capabilities.hasNixOS then "sops"
        else if config.device.capabilities.isDarwin then "age"
        else "gpg"
      else config.services.secrets.backend
    );

    # Auto-configure security integration if available
    services.secrets.integration.security.hardeningLevel = lib.mkDefault (
      config.services.security.hardening.level or "standard"
    );

    # Auto-configure password complexity based on security hardening level
    services.secrets.types.passwords.complexity = lib.mkDefault (
      let hardeningLevel = config.services.security.hardening.level or "standard";
      in if hardeningLevel == "paranoid" then "paranoid"
         else if hardeningLevel == "high" then "high"
         else "standard"
    );

    # Auto-configure audit logging based on security monitoring
    services.secrets.audit.logLevel = lib.mkDefault (
      let hardeningLevel = config.services.security.hardening.level or "standard";
      in if config.services.security.monitoring.enable or false then
           if hardeningLevel == "paranoid" then "paranoid"
           else "detailed"
         else "standard"
    );

    # Auto-configure encryption algorithm based on device capabilities
    services.secrets.storage.encryption.algorithm = lib.mkDefault (
      if config.device.capabilities.hasTPM then "aes256gcm"
      else if config.device.capabilities.hasHardwareRNG then "chacha20poly1305"
      else "age"
    );

    # Auto-configure memory protection on capable devices
    services.secrets.storage.encryption.memoryProtection = lib.mkDefault (
      config.device.capabilities.hasMemoryProtection or true
    );
  };
}