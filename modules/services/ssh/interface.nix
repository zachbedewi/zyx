{ lib, config, pkgs, ... }:

{
  options.services.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable SSH services";
      default = config.device.capabilities.hasNetworking;
    };

    server = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH server (daemon)";
        default = false;
      };

      port = lib.mkOption {
        type = lib.types.port;
        description = "SSH server port";
        default = 22;
      };

      allowedUsers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Users allowed to connect via SSH";
        default = [];
      };

      allowedGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Groups allowed to connect via SSH";
        default = [ "wheel" ];
      };

      hardening = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable SSH server hardening";
          default = config.services.ssh.server.enable;
        };

        level = lib.mkOption {
          type = lib.types.enum [ "standard" "high" "paranoid" ];
          description = "SSH server hardening level";
          default = "standard";
        };

        allowRootLogin = lib.mkOption {
          type = lib.types.bool;
          description = "Allow root login via SSH";
          default = false;
        };

        passwordAuthentication = lib.mkOption {
          type = lib.types.bool;
          description = "Allow password authentication";
          default = false;
        };

        challengeResponseAuthentication = lib.mkOption {
          type = lib.types.bool;
          description = "Allow challenge-response authentication";
          default = false;
        };

        x11Forwarding = lib.mkOption {
          type = lib.types.bool;
          description = "Allow X11 forwarding";
          default = config.device.capabilities.hasGUI && config.services.ssh.server.hardening.level != "paranoid";
        };

        maxAuthTries = lib.mkOption {
          type = lib.types.int;
          description = "Maximum authentication attempts";
          default = 3;
        };

        clientAliveInterval = lib.mkOption {
          type = lib.types.int;
          description = "Client alive interval in seconds";
          default = 300;
        };

        clientAliveCountMax = lib.mkOption {
          type = lib.types.int;
          description = "Maximum client alive count";
          default = 2;
        };
      };

      keyTypes = lib.mkOption {
        type = lib.types.listOf (lib.types.enum [ "ed25519" "rsa" "ecdsa" ]);
        description = "SSH host key types to generate";
        default = [ "ed25519" "rsa" ];
      };

      banner = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "SSH server banner message";
        default = null;
      };
    };

    client = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH client configuration";
        default = config.services.ssh.enable;
      };

      compression = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH compression";
        default = true;
      };

      controlMaster = lib.mkOption {
        type = lib.types.enum [ "auto" "yes" "no" ];
        description = "SSH connection multiplexing";
        default = "auto";
      };

      controlPersist = lib.mkOption {
        type = lib.types.str;
        description = "SSH control connection persistence time";
        default = "10m";
      };

      serverAliveInterval = lib.mkOption {
        type = lib.types.int;
        description = "Server alive interval in seconds";
        default = 60;
      };

      serverAliveCountMax = lib.mkOption {
        type = lib.types.int;
        description = "Maximum server alive count";
        default = 3;
      };

      hashKnownHosts = lib.mkOption {
        type = lib.types.bool;
        description = "Hash known hosts for privacy";
        default = true;
      };

      strictHostKeyChecking = lib.mkOption {
        type = lib.types.enum [ "yes" "no" "ask" ];
        description = "Strict host key checking policy";
        default = "ask";
      };

      profiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            hostname = lib.mkOption {
              type = lib.types.str;
              description = "SSH server hostname or IP";
            };

            user = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Username for SSH connection";
              default = null;
            };

            port = lib.mkOption {
              type = lib.types.port;
              description = "SSH server port";
              default = 22;
            };

            identityFile = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Path to SSH private key";
              default = null;
            };

            identitiesOnly = lib.mkOption {
              type = lib.types.bool;
              description = "Only use specified identity files";
              default = true;
            };

            forwardAgent = lib.mkOption {
              type = lib.types.bool;
              description = "Enable SSH agent forwarding";
              default = false;
            };

            forwardX11 = lib.mkOption {
              type = lib.types.bool;
              description = "Enable X11 forwarding";
              default = false;
            };

            compression = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              description = "Enable compression for this host";
              default = null;
            };

            extraOptions = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              description = "Additional SSH options for this host";
              default = {};
            };
          };
        });
        description = "SSH connection profiles";
        default = {};
      };
    };

    keys = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH key management";
        default = config.services.ssh.enable;
      };

      autoGenerate = lib.mkOption {
        type = lib.types.bool;
        description = "Automatically generate SSH keys if missing";
        default = true;
      };

      keyTypes = lib.mkOption {
        type = lib.types.listOf (lib.types.enum [ "ed25519" "rsa" "ecdsa" ]);
        description = "SSH key types to generate";
        default = [ "ed25519" ];
      };

      keySize = lib.mkOption {
        type = lib.types.int;
        description = "RSA key size in bits";
        default = 4096;
      };

      passphrase = lib.mkOption {
        type = lib.types.bool;
        description = "Generate keys with passphrase protection";
        default = false;
      };

      backup = lib.mkOption {
        type = lib.types.bool;
        description = "Backup SSH keys to secure storage";
        default = false;
      };

      rotation = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable automatic SSH key rotation";
          default = false;
        };

        interval = lib.mkOption {
          type = lib.types.str;
          description = "Key rotation interval (systemd time format)";
          default = "90d";
        };

        keepOldKeys = lib.mkOption {
          type = lib.types.int;
          description = "Number of old keys to keep during rotation";
          default = 2;
        };
      };
    };

    agent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH agent";
        default = config.services.ssh.client.enable && config.device.capabilities.hasGUI;
      };

      timeout = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "SSH agent key timeout";
        default = "1h";
      };

      maxConnections = lib.mkOption {
        type = lib.types.int;
        description = "Maximum SSH agent connections";
        default = 256;
      };

      confirmBeforeUse = lib.mkOption {
        type = lib.types.bool;
        description = "Require confirmation before using keys";
        default = false;
      };
    };

    monitoring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable SSH connection monitoring";
        default = false;
      };

      logLevel = lib.mkOption {
        type = lib.types.enum [ "QUIET" "FATAL" "ERROR" "INFO" "VERBOSE" "DEBUG" ];
        description = "SSH logging level";
        default = "INFO";
      };

      auditSuccessfulLogins = lib.mkOption {
        type = lib.types.bool;
        description = "Audit successful SSH logins";
        default = config.services.ssh.monitoring.enable;
      };

      auditFailedLogins = lib.mkOption {
        type = lib.types.bool;
        description = "Audit failed SSH login attempts";
        default = config.services.ssh.monitoring.enable;
      };

      maxSessions = lib.mkOption {
        type = lib.types.int;
        description = "Maximum concurrent SSH sessions";
        default = 10;
      };

      maxStartups = lib.mkOption {
        type = lib.types.str;
        description = "Maximum unauthenticated connections";
        default = "10:30:100";
      };
    };

    # Internal implementation details
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific SSH implementation";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.ssh.enable {
    # Capability assertions
    assertions = [
      {
        assertion = config.device.capabilities.hasNetworking || !config.services.ssh.enable;
        message = "SSH service requires networking capability";
      }
      {
        assertion = !config.services.ssh.server.enable || config.services.ssh.server.allowedUsers != [] || config.services.ssh.server.allowedGroups != [];
        message = "SSH server requires at least one allowed user or group";
      }
      {
        assertion = !config.services.ssh.server.hardening.passwordAuthentication || config.services.ssh.server.hardening.level == "standard";
        message = "Password authentication is not allowed with high or paranoid hardening levels";
      }
      {
        assertion = !config.services.ssh.keys.rotation.enable || config.services.ssh.keys.enable;
        message = "SSH key rotation requires SSH key management to be enabled";
      }
      {
        assertion = !config.services.ssh.agent.enable || config.services.ssh.client.enable;
        message = "SSH agent requires SSH client to be enabled";
      }
      {
        assertion = !config.services.ssh.monitoring.enable || config.services.ssh.server.enable;
        message = "SSH monitoring requires SSH server to be enabled";
      }
    ];

    # Auto-configure hardening level based on security service (if available)
    services.ssh.server.hardening.level = lib.mkDefault (
      if config.services.security.hardening.level or "standard" == "minimal" then "standard"
      else if config.services.security.hardening.level or "standard" == "standard" then "standard"
      else if config.services.security.hardening.level or "standard" == "high" then "high"
      else "paranoid"
    );

    # Auto-configure key types based on hardening level
    services.ssh.keys.keyTypes = lib.mkDefault (
      if config.services.ssh.server.hardening.level == "paranoid" then [ "ed25519" ]
      else if config.services.ssh.server.hardening.level == "high" then [ "ed25519" "rsa" ]
      else [ "ed25519" "rsa" "ecdsa" ]
    );

    # Auto-configure monitoring based on security monitoring (if available)
    services.ssh.monitoring.enable = lib.mkDefault (
      config.services.ssh.server.enable && 
      config.services.security.monitoring.enable or false
    );
  };
}