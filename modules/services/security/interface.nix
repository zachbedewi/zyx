{ lib, config, pkgs, ... }:

{
  options.services.security = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable security services";
      default = true;
    };

    hardening = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable system hardening";
        default = config.services.security.enable;
      };

      level = lib.mkOption {
        type = lib.types.enum [ "minimal" "standard" "high" "paranoid" ];
        description = "Security hardening level";
        default = "standard";
      };

      kernel = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable kernel security hardening";
          default = config.services.security.hardening.enable;
        };

        mitigations = lib.mkOption {
          type = lib.types.bool;
          description = "Enable CPU vulnerability mitigations";
          default = config.services.security.hardening.kernel.enable;
        };

        lockdown = lib.mkOption {
          type = lib.types.bool;
          description = "Enable kernel lockdown mode";
          default = config.services.security.hardening.level != "minimal";
        };

        modules = {
          blacklist = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Kernel modules to blacklist for security";
            default = [];
          };

          loadOnlyWhitelisted = lib.mkOption {
            type = lib.types.bool;
            description = "Only allow whitelisted kernel modules";
            default = config.services.security.hardening.level == "paranoid";
          };
        };
      };

      filesystem = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable filesystem security hardening";
          default = config.services.security.hardening.enable;
        };

        noexec = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Mount points to mount with noexec";
          default = [ "/tmp" "/var/tmp" "/dev/shm" ];
        };

        hidepid = lib.mkOption {
          type = lib.types.bool;
          description = "Hide processes from other users";
          default = config.services.security.hardening.level != "minimal";
        };

        protectHome = lib.mkOption {
          type = lib.types.bool;
          description = "Protect user home directories";
          default = config.services.security.hardening.filesystem.enable;
        };
      };

      network = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable network security hardening";
          default = config.services.security.hardening.enable;
        };

        disableUnusedProtocols = lib.mkOption {
          type = lib.types.bool;
          description = "Disable unused network protocols";
          default = config.services.security.hardening.network.enable;
        };

        tcpSynProtection = lib.mkOption {
          type = lib.types.bool;
          description = "Enable TCP SYN flood protection";
          default = config.services.security.hardening.network.enable;
        };

        ipv6Privacy = lib.mkOption {
          type = lib.types.bool;
          description = "Enable IPv6 privacy extensions";
          default = config.services.security.hardening.network.enable;
        };
      };
    };

    accessControl = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable access control systems";
        default = config.services.security.enable;
      };

      backend = lib.mkOption {
        type = lib.types.enum [ "selinux" "apparmor" "grsec" "auto" ];
        description = "Access control backend";
        default = "auto";
      };

      enforcing = lib.mkOption {
        type = lib.types.bool;
        description = "Enable enforcing mode (vs. permissive)";
        default = config.services.security.hardening.level != "minimal";
      };

      policies = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            program = lib.mkOption {
              type = lib.types.str;
              description = "Program path or name";
            };

            profile = lib.mkOption {
              type = lib.types.str;
              description = "Security profile to apply";
            };

            capabilities = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Required capabilities";
              default = [];
            };

            networkAccess = lib.mkOption {
              type = lib.types.bool;
              description = "Allow network access";
              default = false;
            };

            filesystemAccess = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Allowed filesystem paths";
              default = [];
            };
          };
        });
        description = "Access control policies";
        default = {};
      };
    };

    monitoring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable security monitoring";
        default = config.services.security.enable;
      };

      auditd = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable audit daemon";
          default = config.services.security.monitoring.enable;
        };

        rules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Custom audit rules";
          default = [];
        };

        logRotation = lib.mkOption {
          type = lib.types.bool;
          description = "Enable audit log rotation";
          default = true;
        };
      };

      intrusion = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable intrusion detection";
          default = config.device.profiles.isWorkstation;
        };

        backend = lib.mkOption {
          type = lib.types.enum [ "aide" "tripwire" "samhain" "auto" ];
          description = "Intrusion detection backend";
          default = "auto";
        };

        realtime = lib.mkOption {
          type = lib.types.bool;
          description = "Enable real-time monitoring";
          default = config.services.security.hardening.level != "minimal";
        };

        alerting = lib.mkOption {
          type = lib.types.bool;
          description = "Enable security alerting";
          default = config.services.security.monitoring.intrusion.enable;
        };
      };

      logging = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable security event logging";
          default = config.services.security.monitoring.enable;
        };

        syslog = lib.mkOption {
          type = lib.types.bool;
          description = "Log security events to syslog";
          default = config.services.security.monitoring.logging.enable;
        };

        journald = lib.mkOption {
          type = lib.types.bool;
          description = "Log security events to journald";
          default = config.services.security.monitoring.logging.enable;
        };

        retention = lib.mkOption {
          type = lib.types.str;
          description = "Log retention period";
          default = "1y";
        };
      };
    };

    compliance = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable compliance frameworks";
        default = config.services.security.hardening.level == "paranoid";
      };

      frameworks = lib.mkOption {
        type = lib.types.listOf (lib.types.enum [ "cis" "nist" "iso27001" "pci-dss" "soc2" ]);
        description = "Compliance frameworks to implement";
        default = [];
      };

      validation = lib.mkOption {
        type = lib.types.bool;
        description = "Enable automated compliance validation";
        default = config.services.security.compliance.enable;
      };

      reporting = lib.mkOption {
        type = lib.types.bool;
        description = "Generate compliance reports";
        default = config.services.security.compliance.enable;
      };
    };

    encryption = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable encryption management";
        default = config.services.security.enable;
      };

      diskEncryption = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable disk encryption";
          default = config.device.capabilities.hasEncryption;
        };

        backend = lib.mkOption {
          type = lib.types.enum [ "luks" "luks2" "zfs" "auto" ];
          description = "Disk encryption backend";
          default = "auto";
        };

        keyfile = lib.mkOption {
          type = lib.types.bool;
          description = "Use keyfile for encryption";
          default = false;
        };
      };

      secureBoot = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable secure boot";
          default = config.device.capabilities.hasSecureBoot;
        };

        keys = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Secure boot signing keys";
          default = [];
        };

        selfSigned = lib.mkOption {
          type = lib.types.bool;
          description = "Use self-signed secure boot keys";
          default = true;
        };
      };

      tpm = {
        enable = lib.mkOption {
          type = lib.types.bool;
          description = "Enable TPM integration";
          default = config.device.capabilities.hasTPM;
        };

        version = lib.mkOption {
          type = lib.types.enum [ "1.2" "2.0" "auto" ];
          description = "TPM version";
          default = "auto";
        };

        attestation = lib.mkOption {
          type = lib.types.bool;
          description = "Enable TPM attestation";
          default = config.services.security.encryption.tpm.enable;
        };
      };
    };

    # Internal implementation details
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific security implementation details";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.security.enable {
    # Capability assertions
    assertions = [
      {
        assertion = config.services.security.encryption.diskEncryption.enable -> config.device.capabilities.hasEncryption;
        message = "Disk encryption requires encryption capability";
      }
      {
        assertion = config.services.security.encryption.secureBoot.enable -> config.device.capabilities.hasSecureBoot;
        message = "Secure boot requires secure boot capability";
      }
      {
        assertion = config.services.security.encryption.tpm.enable -> config.device.capabilities.hasTPM;
        message = "TPM integration requires TPM capability";
      }
      {
        assertion = 
          let invalidCompliance = lib.any (f: f == "pci-dss" && !config.device.profiles.isWorkstation) config.services.security.compliance.frameworks;
          in !invalidCompliance;
        message = "PCI-DSS compliance requires workstation profile";
      }
      {
        assertion = config.services.security.accessControl.enforcing -> config.services.security.accessControl.enable;
        message = "Access control enforcing mode requires access control to be enabled";
      }
    ];

    # Auto-select backends based on platform capabilities
    services.security.accessControl.backend = lib.mkDefault (
      if config.platform.capabilities.isDarwin then "auto"  # macOS uses built-in sandboxing
      else if config.device.capabilities.hasSELinux then "selinux"
      else "apparmor"
    );

    services.security.monitoring.intrusion.backend = lib.mkDefault (
      if config.platform.capabilities.supportsNixOS then "aide"
      else "auto"
    );

    services.security.encryption.diskEncryption.backend = lib.mkDefault (
      if config.platform.capabilities.supportsZFS then "zfs"
      else "luks2"
    );

    # Adjust hardening level based on device profile
    services.security.hardening.level = lib.mkDefault (
      if config.device.profiles.isServer then "high"
      else if config.device.profiles.isWorkstation then "standard"
      else "minimal"
    );

    # Add security tools based on capabilities and hardening level
    environment.systemPackages = lib.optionals config.platform.capabilities.supportsNixOS [
      # Basic security tools
      pkgs.openssl
      pkgs.gnupg
    ] ++ lib.optionals (config.services.security.hardening.level != "minimal" && config.platform.capabilities.supportsNixOS) [
      # Enhanced security tools
      pkgs.lynis
      pkgs.chkrootkit
      pkgs.rkhunter
    ] ++ lib.optionals (config.services.security.monitoring.enable && config.platform.capabilities.supportsNixOS) [
      # Security monitoring tools
      pkgs.aide
      pkgs.auditd
    ] ++ lib.optionals (config.services.security.hardening.level == "paranoid" && config.platform.capabilities.supportsNixOS) [
      # Advanced security tools
      pkgs.samhain
      pkgs.tiger
      pkgs.unhide
    ];
  };
}