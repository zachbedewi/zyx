{ lib, config, pkgs, ... }:

let
  sshConfig = config.services.ssh;
  
  # Helper functions for SSH configuration
  
  # Generate SSH server configuration based on hardening level
  mkServerConfig = level: {
    protocol = "2";
    
    # Authentication settings
    permitRootLogin = if sshConfig.server.hardening.allowRootLogin then "yes" else "no";
    passwordAuthentication = sshConfig.server.hardening.passwordAuthentication;
    challengeResponseAuthentication = sshConfig.server.hardening.challengeResponseAuthentication;
    pubkeyAuthentication = true;
    authenticationMethods = if level == "paranoid" then "publickey" else null;
    maxAuthTries = sshConfig.server.hardening.maxAuthTries;
    
    # Connection settings
    port = sshConfig.server.port;
    clientAliveInterval = sshConfig.server.hardening.clientAliveInterval;
    clientAliveCountMax = sshConfig.server.hardening.clientAliveCountMax;
    maxSessions = sshConfig.monitoring.maxSessions;
    maxStartups = sshConfig.monitoring.maxStartups;
    
    # Security settings
    x11Forwarding = sshConfig.server.hardening.x11Forwarding;
    allowAgentForwarding = level != "paranoid";
    allowTcpForwarding = if level == "paranoid" then "no" else "yes";
    gatewayPorts = "no";
    permitTunnel = if level == "paranoid" then "no" else "yes";
    
    # Crypto settings based on hardening level
    kexAlgorithms = if level == "paranoid" then [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
    ] else if level == "high" then [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "ecdh-sha2-nistp521"
      "ecdh-sha2-nistp384"
      "ecdh-sha2-nistp256"
      "diffie-hellman-group16-sha512"
    ] else null;
    
    ciphers = if level == "paranoid" then [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
    ] else if level == "high" then [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
      "aes256-ctr"
      "aes192-ctr"
      "aes128-ctr"
    ] else null;
    
    macs = if level == "paranoid" then [
      "hmac-sha2-256-etm@openssh.com"
      "hmac-sha2-512-etm@openssh.com"
    ] else if level == "high" then [
      "hmac-sha2-256-etm@openssh.com"
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256"
      "hmac-sha2-512"
    ] else null;
    
    # Logging
    logLevel = sshConfig.monitoring.logLevel;
    
    # User/Group restrictions
    allowUsers = lib.mkIf (sshConfig.server.allowedUsers != []) sshConfig.server.allowedUsers;
    allowGroups = lib.mkIf (sshConfig.server.allowedGroups != []) sshConfig.server.allowedGroups;
    
    # Banner
    banner = lib.mkIf (sshConfig.server.banner != null) (pkgs.writeText "ssh-banner" sshConfig.server.banner);
  };

  # Generate SSH client configuration
  mkClientConfig = profiles: ''
    # Global SSH client configuration
    Host *
      Compression ${if sshConfig.client.compression then "yes" else "no"}
      ControlMaster ${sshConfig.client.controlMaster}
      ControlPersist ${sshConfig.client.controlPersist}
      ControlPath ~/.ssh/master-%r@%h:%p
      ServerAliveInterval ${toString sshConfig.client.serverAliveInterval}
      ServerAliveCountMax ${toString sshConfig.client.serverAliveCountMax}
      HashKnownHosts ${if sshConfig.client.hashKnownHosts then "yes" else "no"}
      StrictHostKeyChecking ${sshConfig.client.strictHostKeyChecking}
      AddKeysToAgent yes
      UseKeychain yes
      IdentitiesOnly no
      
      # Security-focused cipher selection
      ${lib.optionalString (sshConfig.server.hardening.level == "paranoid") ''
        KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
        Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
        MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
      ''}
      
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: profile: ''
      Host ${name}
        HostName ${profile.hostname}
        ${lib.optionalString (profile.user != null) "User ${profile.user}"}
        Port ${toString profile.port}
        ${lib.optionalString (profile.identityFile != null) "IdentityFile ${profile.identityFile}"}
        IdentitiesOnly ${if profile.identitiesOnly then "yes" else "no"}
        ForwardAgent ${if profile.forwardAgent then "yes" else "no"}
        ForwardX11 ${if profile.forwardX11 then "yes" else "no"}
        ${lib.optionalString (profile.compression != null) "Compression ${if profile.compression then "yes" else "no"}"}
        ${lib.concatStringsSep "\n  " (lib.mapAttrsToList (key: value: "${key} ${value}") profile.extraOptions)}
    '') profiles)}
  '';

  # Generate SSH key management scripts
  mkKeyManagementScripts = keyTypes: {
    ssh-keygen-all = pkgs.writeShellScriptBin "ssh-keygen-all" ''
      set -euo pipefail
      
      SSH_DIR="$HOME/.ssh"
      mkdir -p "$SSH_DIR"
      chmod 700 "$SSH_DIR"
      
      ${lib.concatMapStringsSep "\n" (keyType: 
        let
          keyFile = if keyType == "ed25519" then "id_ed25519"
                   else if keyType == "rsa" then "id_rsa"
                   else if keyType == "ecdsa" then "id_ecdsa"
                   else "id_${keyType}";
        in ''
          if [[ ! -f "$SSH_DIR/${keyFile}" ]]; then
            echo "Generating ${keyType} key..."
            ${if keyType == "rsa" then 
              "ssh-keygen -t rsa -b ${toString sshConfig.keys.keySize} -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\""
             else if keyType == "ed25519" then
              "ssh-keygen -t ed25519 -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\""
             else
              "ssh-keygen -t ${keyType} -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\""
            }
            chmod 600 "$SSH_DIR/${keyFile}"
            chmod 644 "$SSH_DIR/${keyFile}.pub"
            echo "Generated ${keyType} key: $SSH_DIR/${keyFile}"
          else
            echo "${keyType} key already exists: $SSH_DIR/${keyFile}"
          fi
        ''
      ) keyTypes}
      
      echo "SSH key generation complete."
    '';
    
    ssh-key-rotate = pkgs.writeShellScriptBin "ssh-key-rotate" ''
      set -euo pipefail
      
      SSH_DIR="$HOME/.ssh"
      BACKUP_DIR="$SSH_DIR/backup-$(date +%Y%m%d-%H%M%S)"
      
      echo "Starting SSH key rotation..."
      mkdir -p "$BACKUP_DIR"
      
      ${lib.concatMapStringsSep "\n" (keyType:
        let
          keyFile = if keyType == "ed25519" then "id_ed25519"
                   else if keyType == "rsa" then "id_rsa" 
                   else if keyType == "ecdsa" then "id_ecdsa"
                   else "id_${keyType}";
        in ''
          if [[ -f "$SSH_DIR/${keyFile}" ]]; then
            echo "Rotating ${keyType} key..."
            cp "$SSH_DIR/${keyFile}" "$BACKUP_DIR/"
            cp "$SSH_DIR/${keyFile}.pub" "$BACKUP_DIR/"
            
            # Generate new key
            ${if keyType == "rsa" then 
              "ssh-keygen -t rsa -b ${toString sshConfig.keys.keySize} -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\" -f \"$SSH_DIR/${keyFile}\""
             else if keyType == "ed25519" then
              "ssh-keygen -t ed25519 -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\" -f \"$SSH_DIR/${keyFile}\""
             else
              "ssh-keygen -t ${keyType} -f \"$SSH_DIR/${keyFile}\" -N \"\" -C \"$(whoami)@$(hostname)-$(date +%Y%m%d)\" -f \"$SSH_DIR/${keyFile}\""
            }
            chmod 600 "$SSH_DIR/${keyFile}"
            chmod 644 "$SSH_DIR/${keyFile}.pub"
            echo "Rotated ${keyType} key, backup in $BACKUP_DIR"
          fi
        ''
      ) keyTypes}
      
      # Clean up old backups, keeping only the specified number
      KEEP_BACKUPS=${toString sshConfig.keys.rotation.keepOldKeys}
      find "$SSH_DIR" -maxdepth 1 -name "backup-*" -type d | sort -r | tail -n +$((KEEP_BACKUPS + 1)) | xargs rm -rf
      
      echo "SSH key rotation complete. Backups in $BACKUP_DIR"
      echo "Remember to update your public keys on remote servers!"
    '';
  };

  # Generate fail2ban SSH jail configuration
  mkFail2banSSHJail = {
    ssh = {
      enabled = true;
      filter = "sshd";
      logpath = "/var/log/auth.log";
      maxretry = sshConfig.server.hardening.maxAuthTries;
      bantime = if sshConfig.server.hardening.level == "paranoid" then "1d"
               else if sshConfig.server.hardening.level == "high" then "1h"
               else "10m";
      findtime = "10m";
      action = if sshConfig.server.hardening.level == "paranoid" then 
                 "%(action_mwl)s" # Mail with whois and log lines
               else "%(action_mw)s"; # Mail with whois
    };
  };

in {
  config = lib.mkIf (
    sshConfig.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    
    # SSH Server Configuration
    services.openssh = lib.mkIf sshConfig.server.enable (mkServerConfig sshConfig.server.hardening.level // {
      enable = true;
      hostKeys = map (keyType: {
        type = keyType;
        bits = if keyType == "rsa" then 4096 else null;
        path = "/etc/ssh/ssh_host_${keyType}_key";
      }) sshConfig.server.keyTypes;
    });

    # SSH Client Configuration
    programs.ssh = lib.mkIf sshConfig.client.enable {
      enable = true;
      extraConfig = mkClientConfig sshConfig.client.profiles;
    };

    # SSH Agent Configuration
    programs.ssh.startAgent = lib.mkIf sshConfig.agent.enable true;
    
    services.openssh.extraConfig = lib.mkIf (sshConfig.agent.enable && sshConfig.server.enable) ''
      # SSH Agent settings
      MaxSessions ${toString sshConfig.agent.maxConnections}
      ${lib.optionalString (sshConfig.agent.timeout != null) 
        "ClientAliveInterval ${sshConfig.agent.timeout}"}
    '';

    # SSH Key Management
    environment.systemPackages = lib.optionals sshConfig.keys.enable (
      lib.attrValues (mkKeyManagementScripts sshConfig.keys.keyTypes) ++ [
        pkgs.openssh
        pkgs.ssh-copy-id
      ]
    );

    # User SSH key generation service
    systemd.user.services.ssh-key-generation = lib.mkIf (sshConfig.keys.enable && sshConfig.keys.autoGenerate) {
      description = "Generate SSH keys if missing";
      wantedBy = [ "default.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${(mkKeyManagementScripts sshConfig.keys.keyTypes).ssh-keygen-all}/bin/ssh-keygen-all";
      };
    };

    # SSH Key Rotation Timer
    systemd.user.services.ssh-key-rotation = lib.mkIf (sshConfig.keys.enable && sshConfig.keys.rotation.enable) {
      description = "Rotate SSH keys";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${(mkKeyManagementScripts sshConfig.keys.keyTypes).ssh-key-rotate}/bin/ssh-key-rotate";
      };
    };

    systemd.user.timers.ssh-key-rotation = lib.mkIf (sshConfig.keys.enable && sshConfig.keys.rotation.enable) {
      description = "SSH key rotation timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = sshConfig.keys.rotation.interval;
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };

    # Firewall Configuration
    networking.firewall = lib.mkIf sshConfig.server.enable {
      allowedTCPPorts = [ sshConfig.server.port ];
    };

    # Fail2ban Integration for SSH monitoring
    services.fail2ban = lib.mkIf (sshConfig.monitoring.enable && config.services.security.monitoring.enable) {
      enable = true;
      jails = mkFail2banSSHJail;
    };

    # SSH Audit Logging
    security.auditd.rules = lib.mkIf (sshConfig.monitoring.enable && config.services.security.monitoring.enable) [
      # Monitor SSH logins
      "-w /var/log/auth.log -p wa -k ssh-auth"
      "-w /var/log/secure -p wa -k ssh-auth"
      "-w /etc/ssh/sshd_config -p wa -k ssh-config"
      "-w /etc/ssh/ -p wa -k ssh-config"
      
      # Monitor SSH key access
      "-a always,exit -F arch=b64 -S openat -F dir=/home -F success=1 -k ssh-key-access"
      "-a always,exit -F arch=b32 -S openat -F dir=/home -F success=1 -k ssh-key-access"
    ];

    # SSH Banner Configuration
    environment.etc."ssh/banner" = lib.mkIf (sshConfig.server.enable && sshConfig.server.banner != null) {
      text = sshConfig.server.banner;
      mode = "0644";
    };

    # Store implementation metadata for introspection
    services.ssh._implementation = {
      platform = "nixos";
      serverEnabled = sshConfig.server.enable;
      clientEnabled = sshConfig.client.enable;
      agentEnabled = sshConfig.agent.enable;
      keyManagementEnabled = sshConfig.keys.enable;
      monitoringEnabled = sshConfig.monitoring.enable;
      hardeningLevel = sshConfig.server.hardening.level;
      keyTypes = sshConfig.keys.keyTypes;
      profileCount = lib.length (lib.attrNames sshConfig.client.profiles);
      fail2banEnabled = sshConfig.monitoring.enable && config.services.security.monitoring.enable;
    };
  };
}