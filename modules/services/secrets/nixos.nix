{ lib, config, pkgs, ... }:

let
  secretsConfig = config.services.secrets;
  
  # Helper functions for secrets management
  
  # Backend-specific package selection
  backendPackages = {
    sops = [ pkgs.sops pkgs.age ];
    agenix = [ pkgs.agenix pkgs.age ];
    age = [ pkgs.age ];
    gpg = [ pkgs.gnupg ];
    pass = [ pkgs.pass pkgs.gnupg ];
    vault = [ pkgs.vault ];
  };

  # Generate encryption configuration based on algorithm and settings
  mkEncryptionConfig = algorithm: settings: {
    algorithm = algorithm;
    keyDerivation = settings.keyDerivation;
    memoryProtection = settings.memoryProtection;
    
    # Algorithm-specific settings
    options = if algorithm == "age" then {
      armorOutput = true;
      scryptWork = if settings.keyDerivation == "scrypt" then 20 else null;
    } else if algorithm == "gpg" then {
      compression = 2; # ZLIB compression
      cipherAlgo = "AES256";
      digestAlgo = "SHA512";
    } else if algorithm == "chacha20poly1305" then {
      keySize = 256;
      nonceSize = 96;
    } else if algorithm == "aes256gcm" then {
      keySize = 256;
      ivSize = 96;
      tagSize = 128;
    } else {};
  };

  # Generate access control policies
  mkAccessPolicy = name: policy: {
    inherit name;
    users = policy.users;
    groups = policy.groups;
    services = policy.services;
    permissions = policy.permissions;
    timeRestrictions = policy.timeRestrictions;
    
    # Convert to filesystem permissions
    mode = let
      hasWrite = lib.elem "write" policy.permissions;
      hasRead = lib.elem "read" policy.permissions;
    in if hasWrite then "0640" else if hasRead then "0440" else "0000";
  };

  # Password complexity settings
  passwordComplexitySettings = {
    basic = {
      minLength = 8;
      requireUppercase = false;
      requireLowercase = true;
      requireNumbers = false;
      requireSymbols = false;
      excludeCommonWords = false;
    };
    standard = {
      minLength = 12;
      requireUppercase = true;
      requireLowercase = true;
      requireNumbers = true;
      requireSymbols = false;
      excludeCommonWords = true;
    };
    high = {
      minLength = 16;
      requireUppercase = true;
      requireLowercase = true;
      requireNumbers = true;
      requireSymbols = true;
      excludeCommonWords = true;
    };
    paranoid = {
      minLength = 24;
      requireUppercase = true;
      requireLowercase = true;
      requireNumbers = true;
      requireSymbols = true;
      excludeCommonWords = true;
    };
  };

  # Secret generation templates
  secretTemplates = lib.mapAttrs (name: template: {
    inherit name;
    type = template.type;
    length = template.length or (
      if template.type == "password" then passwordComplexitySettings.${secretsConfig.types.passwords.complexity}.minLength
      else if template.type == "apiKey" then 32
      else if template.type == "sshKey" then null
      else 16
    );
    complexity = template.complexity or secretsConfig.types.passwords.complexity;
    template = template.template;
  }) secretsConfig.automation.provisioning.templates;

  # Backend initialization scripts
  backendInitScripts = {
    sops = ''
      # Initialize SOPS configuration
      mkdir -p /etc/sops
      ${lib.optionalString (secretsConfig.storage.encryption.algorithm == "age") ''
        if [[ ! -f /etc/sops/age/keys.txt ]]; then
          mkdir -p /etc/sops/age
          ${pkgs.age}/bin/age-keygen -o /etc/sops/age/keys.txt
          chmod 600 /etc/sops/age/keys.txt
        fi
      ''}
    '';
    
    agenix = ''
      # Initialize agenix configuration
      mkdir -p /etc/agenix
      if [[ ! -f /etc/agenix/system.age ]]; then
        ${pkgs.age}/bin/age-keygen -o /etc/agenix/system.age
        chmod 600 /etc/agenix/system.age
      fi
    '';
    
    age = ''
      # Initialize age configuration
      mkdir -p ${secretsConfig.storage.location}/.age
      if [[ ! -f ${secretsConfig.storage.location}/.age/key.txt ]]; then
        ${pkgs.age}/bin/age-keygen -o ${secretsConfig.storage.location}/.age/key.txt
        chmod 600 ${secretsConfig.storage.location}/.age/key.txt
      fi
    '';
    
    gpg = ''
      # Initialize GPG configuration
      mkdir -p ${secretsConfig.storage.location}/.gnupg
      chmod 700 ${secretsConfig.storage.location}/.gnupg
      export GNUPGHOME="${secretsConfig.storage.location}/.gnupg"
      if ! ${pkgs.gnupg}/bin/gpg --list-secret-keys | grep -q "sec "; then
        ${pkgs.gnupg}/bin/gpg --batch --generate-key << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Zyx Secrets Management
Name-Email: secrets@localhost
Expire-Date: 2y
%no-protection
%commit
EOF
      fi
    '';
  };

in {
  config = lib.mkIf (
    secretsConfig.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    
    # Install backend packages
    environment.systemPackages = 
      backendPackages.${secretsConfig.backend} or [] ++
      lib.optionals secretsConfig.audit.enable [ pkgs.auditd ] ++
      lib.optionals secretsConfig.automation.enable [ pkgs.systemd ];

    # Create secrets storage directory
    systemd.tmpfiles.rules = [
      "d ${secretsConfig.storage.location} 0750 root ${lib.head secretsConfig.access.groups} -"
      "d ${secretsConfig.storage.location}/keys 0700 root root -"
      "d ${secretsConfig.storage.location}/audit 0750 root ${lib.head secretsConfig.access.groups} -"
    ] ++ lib.optionals secretsConfig.storage.backup.enable [
      "d ${secretsConfig.storage.backup.location} 0750 root ${lib.head secretsConfig.access.groups} -"
    ];

    # Backend initialization service
    systemd.services.secrets-init = {
      description = "Initialize secrets management backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      script = backendInitScripts.${secretsConfig.backend} or "";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
        Group = lib.head secretsConfig.access.groups;
        UMask = "0027";
      };
    };

    # Secret rotation service
    systemd.services.secrets-rotation = lib.mkIf secretsConfig.automation.rotation.enable {
      description = "Automatic secret rotation";
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        SECRETS_DIR="${secretsConfig.storage.location}"
        BACKEND="${secretsConfig.backend}"
        
        # Log rotation start
        echo "$(date): Starting secret rotation" >> "$SECRETS_DIR/audit/rotation.log"
        
        # Rotate secrets based on their age and rotation policy
        find "$SECRETS_DIR" -name "*.secret" -type f | while read -r secret_file; do
          secret_name=$(basename "$secret_file" .secret)
          secret_age=$(stat -c %Y "$secret_file")
          current_time=$(date +%s)
          age_days=$(( (current_time - secret_age) / 86400 ))
          
          # Check if secret needs rotation
          max_age_days=$(echo "${secretsConfig.automation.lifecycle.maxAge}" | sed 's/d$//')
          if [ "$age_days" -gt "$max_age_days" ]; then
            echo "$(date): Rotating secret: $secret_name (age: $age_days days)" >> "$SECRETS_DIR/audit/rotation.log"
            
            # Backup old secret
            cp "$secret_file" "$secret_file.$(date +%Y%m%d_%H%M%S).bak"
            
            # Generate new secret based on type
            secret_type=$(head -n1 "$secret_file.meta" 2>/dev/null | cut -d: -f2 || echo "password")
            case "$secret_type" in
              "password")
                ${pkgs.pwgen}/bin/pwgen -s ${toString secretsConfig.types.passwords.length} 1 > "$secret_file.new"
                ;;
              "apiKey")
                ${pkgs.openssl}/bin/openssl rand -hex 32 > "$secret_file.new"
                ;;
              *)
                echo "Unknown secret type: $secret_type" >&2
                continue
                ;;
            esac
            
            # Encrypt new secret
            case "$BACKEND" in
              "age"|"agenix")
                ${pkgs.age}/bin/age -r $(cat ${secretsConfig.storage.location}/.age/key.txt.pub 2>/dev/null || echo "age1...") -o "$secret_file" "$secret_file.new"
                ;;
              "gpg")
                export GNUPGHOME="${secretsConfig.storage.location}/.gnupg"
                ${pkgs.gnupg}/bin/gpg --encrypt --armor -r secrets@localhost -o "$secret_file" "$secret_file.new"
                ;;
              "sops")
                ${pkgs.sops}/bin/sops -e "$secret_file.new" > "$secret_file"
                ;;
            esac
            
            # Clean up temporary file
            rm -f "$secret_file.new"
            
            echo "$(date): Secret rotated: $secret_name" >> "$SECRETS_DIR/audit/rotation.log"
          fi
        done
        
        echo "$(date): Secret rotation completed" >> "$SECRETS_DIR/audit/rotation.log"
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = lib.head secretsConfig.access.groups;
        UMask = "0027";
      };
    };

    # Secret rotation timer
    systemd.timers.secrets-rotation = lib.mkIf secretsConfig.automation.rotation.enable {
      description = "Timer for automatic secret rotation";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = secretsConfig.automation.rotation.schedule;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # Secret backup service
    systemd.services.secrets-backup = lib.mkIf secretsConfig.storage.backup.enable {
      description = "Backup secrets to secure storage";
      script = ''
        #!/bin/bash
        set -euo pipefail
        
        SECRETS_DIR="${secretsConfig.storage.location}"
        BACKUP_DIR="${secretsConfig.storage.backup.location}"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        # Create backup directory
        mkdir -p "$BACKUP_DIR"
        
        # Create encrypted backup
        tar -czf - -C "$SECRETS_DIR" . | \
        ${if secretsConfig.storage.encryption.algorithm == "age" then
          "${pkgs.age}/bin/age -r $(cat $SECRETS_DIR/.age/key.txt.pub)"
        else if secretsConfig.storage.encryption.algorithm == "gpg" then
          "GNUPGHOME=$SECRETS_DIR/.gnupg ${pkgs.gnupg}/bin/gpg --encrypt --armor -r secrets@localhost"
        else
          "cat"
        } > "$BACKUP_DIR/secrets_backup_$TIMESTAMP.tar.gz${if secretsConfig.storage.encryption.enable then ".enc" else ""}"
        
        # Clean up old backups
        find "$BACKUP_DIR" -name "secrets_backup_*.tar.gz*" -type f -mtime +${toString secretsConfig.storage.backup.retention} -delete
        
        echo "$(date): Backup completed: secrets_backup_$TIMESTAMP" >> "$SECRETS_DIR/audit/backup.log"
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = lib.head secretsConfig.access.groups;
        UMask = "0027";
      };
    };

    # Secret backup timer
    systemd.timers.secrets-backup = lib.mkIf secretsConfig.storage.backup.enable {
      description = "Timer for automatic secret backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = secretsConfig.storage.backup.interval;
        Persistent = true;
        RandomizedDelaySec = "30m";
      };
    };

    # Audit logging configuration
    security.auditd.enable = lib.mkIf secretsConfig.audit.enable true;
    security.audit.rules = lib.mkIf secretsConfig.audit.enable [
      # Monitor secret storage directory
      "-w ${secretsConfig.storage.location} -p rwxa -k secrets-access"
      
      # Monitor secret management commands
      "-w /run/current-system/sw/bin/sops -p x -k secrets-sops"
      "-w /run/current-system/sw/bin/age -p x -k secrets-age"
      "-w /run/current-system/sw/bin/gpg -p x -k secrets-gpg"
    ];

    # SSH integration
    services.openssh = lib.mkIf (
      secretsConfig.integration.ssh.enable && 
      secretsConfig.integration.ssh.keyProvisioning
    ) {
      # This would integrate with SSH key provisioning
      # Implementation depends on specific SSH service configuration
    };

    # Security integration - inherit hardening settings
    services.secrets._implementation = {
      platform = "nixos";
      backend = secretsConfig.backend;
      encryptionConfig = mkEncryptionConfig 
        secretsConfig.storage.encryption.algorithm 
        secretsConfig.storage.encryption;
      accessPolicies = lib.mapAttrsToList mkAccessPolicy secretsConfig.access.policies;
      secretTemplates = secretTemplates;
      
      # Backend-specific configuration
      backendConfig = if secretsConfig.backend == "sops" then {
        configPath = "/etc/sops/age/keys.txt";
        format = "yaml";
      } else if secretsConfig.backend == "agenix" then {
        identityPaths = [ "/etc/agenix/system.age" ];
      } else if secretsConfig.backend == "age" then {
        keyPath = "${secretsConfig.storage.location}/.age/key.txt";
      } else if secretsConfig.backend == "gpg" then {
        gnupgHome = "${secretsConfig.storage.location}/.gnupg";
        keyId = "secrets@localhost";
      } else {};
      
      # Service status
      servicesEnabled = {
        storage = secretsConfig.storage.enable;
        encryption = secretsConfig.storage.encryption.enable;
        backup = secretsConfig.storage.backup.enable;
        automation = secretsConfig.automation.enable;
        rotation = secretsConfig.automation.rotation.enable;
        audit = secretsConfig.audit.enable;
      };
      
      # Integration status
      integrations = {
        ssh = secretsConfig.integration.ssh.enable;
        security = secretsConfig.integration.security.enable;
        networking = secretsConfig.integration.networking.enable;
      };
    };

    # Memory protection for secrets (if supported)
    boot.kernel.sysctl = lib.mkIf secretsConfig.storage.encryption.memoryProtection {
      "kernel.yama.ptrace_scope" = 2; # Restrict ptrace to prevent memory dumps
      "vm.mmap_min_addr" = 65536; # Prevent mapping at low addresses
    };

    # Environment variables for secret management tools
    environment.variables = {
      SECRETS_BACKEND = secretsConfig.backend;
      SECRETS_STORAGE = secretsConfig.storage.location;
    } // lib.optionalAttrs (secretsConfig.backend == "sops") {
      SOPS_AGE_KEY_FILE = "/etc/sops/age/keys.txt";
    } // lib.optionalAttrs (secretsConfig.backend == "agenix") {
      AGENIX_IDENTITY = "/etc/agenix/system.age";
    } // lib.optionalAttrs (secretsConfig.backend == "gpg") {
      GNUPGHOME = "${secretsConfig.storage.location}/.gnupg";
    };

    # Group management for secret access
    users.groups = lib.listToAttrs (map (group: {
      name = group;
      value = {};
    }) secretsConfig.access.groups);
  };
}