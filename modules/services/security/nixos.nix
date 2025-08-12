{ lib, config, pkgs, ... }:

let
  securityConfig = config.services.security;
  
  # Helper functions for security configuration
  
  # Generate kernel parameters based on hardening level
  mkKernelParams = level: lib.flatten [
    # Basic hardening (all levels)
    [ "kernel.dmesg_restrict=1" ]
    [ "kernel.kptr_restrict=2" ]
    [ "kernel.unprivileged_bpf_disabled=1" ]
    [ "net.core.bpf_jit_harden=2" ]
    
    # Standard hardening
    (lib.optionals (level != "minimal") [
      "kernel.yama.ptrace_scope=1"
      "kernel.kexec_load_disabled=1" 
      "kernel.sysrq=0"
      "net.ipv4.conf.all.log_martians=1"
      "net.ipv4.conf.default.log_martians=1"
      "net.ipv4.icmp_ignore_bogus_error_responses=1"
      "net.ipv4.conf.all.accept_redirects=0"
      "net.ipv4.conf.default.accept_redirects=0"
      "net.ipv6.conf.all.accept_redirects=0"
      "net.ipv6.conf.default.accept_redirects=0"
    ])
    
    # High hardening
    (lib.optionals (level == "high" || level == "paranoid") [
      "kernel.unprivileged_userns_clone=0"
      "kernel.modules_disabled=1"
      "net.ipv4.tcp_syncookies=1"
      "net.ipv4.tcp_rfc1337=1"
      "net.ipv4.conf.all.accept_source_route=0"
      "net.ipv4.conf.default.accept_source_route=0"
      "net.ipv6.conf.all.accept_source_route=0"
      "net.ipv6.conf.default.accept_source_route=0"
    ])
    
    # Paranoid hardening
    (lib.optionals (level == "paranoid") [
      "kernel.panic_on_oops=1"
      "kernel.panic=10"
      "vm.unprivileged_userfaultfd=0"
      "dev.tty.ldisc_autoload=0"
    ])
  ];

  # Generate blacklisted kernel modules
  mkBlacklistedModules = modules: lib.flatten [
    # Default security blacklist
    [ "dccp" "sctp" "rds" "tipc" ]  # Uncommon network protocols
    [ "n-hdlc" "ax25" "netrom" "x25" "rose" ]  # Amateur radio protocols  
    [ "decnet" "econet" "af_802154" "ipx" "appletalk" ]  # Legacy protocols
    [ "psnap" "p8023" "p8022" "can" "atm" ]  # Specialized protocols
    
    # USB and Firewire (if paranoid)
    (lib.optionals (securityConfig.hardening.level == "paranoid") [
      "usb-storage" "uas" "firewire-ohci" "firewire-sbp2"
    ])
    
    # Custom blacklist
    modules
  ];

  # Generate AppArmor profiles
  mkApparmorProfiles = policies: lib.mapAttrs (name: policy: ''
    #include <tunables/global>
    
    ${policy.program} {
      #include <abstractions/base>
      ${lib.optionalString policy.networkAccess "#include <abstractions/nameservice>"}
      ${lib.optionalString policy.networkAccess "#include <abstractions/ssl_certs>"}
      
      # Capabilities
      ${lib.concatMapStringsSep "\n  " (cap: "capability ${cap},") policy.capabilities}
      
      # Filesystem access
      ${lib.concatMapStringsSep "\n  " (path: "${path} rw,") policy.filesystemAccess}
      
      # Network access
      ${lib.optionalString policy.networkAccess "network inet dgram,"}
      ${lib.optionalString policy.networkAccess "network inet6 dgram,"}
      ${lib.optionalString policy.networkAccess "network inet stream,"}
      ${lib.optionalString policy.networkAccess "network inet6 stream,"}
    }
  '') policies;

  # Generate audit rules
  mkAuditRules = rules: lib.flatten [
    # Default audit rules based on hardening level
    (lib.optionals (securityConfig.hardening.level != "minimal") [
      # Monitor authentication events
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/group -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"
      "-w /etc/gshadow -p wa -k identity"
      
      # Monitor sudo events
      "-w /etc/sudoers -p wa -k scope"
      "-w /etc/sudoers.d/ -p wa -k scope"
      
      # Monitor system configuration
      "-w /etc/ssh/sshd_config -p wa -k sshd"
      "-w /etc/hosts -p wa -k hosts"
    ])
    
    (lib.optionals (securityConfig.hardening.level == "high" || securityConfig.hardening.level == "paranoid") [
      # Monitor privileged commands
      "-a always,exit -F arch=b64 -S execve -F euid=0 -k privileged"
      "-a always,exit -F arch=b32 -S execve -F euid=0 -k privileged"
      
      # Monitor network configuration
      "-a always,exit -F arch=b64 -S socket -F a0=10 -k network"
      "-a always,exit -F arch=b32 -S socket -F a0=10 -k network"
      
      # Monitor file permission changes
      "-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -k perm_mod"
      "-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -k perm_mod"
    ])
    
    # Custom audit rules
    rules
  ];

  # Generate compliance configurations
  mkComplianceConfig = frameworks: lib.foldl (acc: framework:
    if framework == "cis" then acc // {
      # CIS Benchmark controls
      kernel.parameters = acc.kernel.parameters ++ [
        "fs.suid_dumpable=0"
        "kernel.randomize_va_space=2"
      ];
      services.sshd.settings = acc.services.sshd.settings // {
        Protocol = 2;
        LogLevel = "INFO";
        X11Forwarding = false;
        MaxAuthTries = 4;
        IgnoreRhosts = true;
        HostbasedAuthentication = false;
        PermitRootLogin = "no";
        PermitEmptyPasswords = false;
        PermitUserEnvironment = false;
        ClientAliveInterval = 300;
        ClientAliveCountMax = 0;
        LoginGraceTime = 60;
        Banner = "/etc/issue.net";
      };
    }
    else if framework == "nist" then acc // {
      # NIST 800-53 controls
      auditd.extraRules = acc.auditd.extraRules ++ [
        "-a always,exit -F arch=b64 -S adjtimex,settimeofday,clock_settime -k time-change"
        "-a always,exit -F arch=b32 -S adjtimex,settimeofday,stime,clock_settime -k time-change"
        "-w /etc/localtime -p wa -k time-change"
      ];
    }
    else acc
  ) { kernel.parameters = []; services.sshd.settings = {}; auditd.extraRules = []; } frameworks;

in {
  config = lib.mkIf (
    config.services.security.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    
    # Kernel Hardening Configuration
    boot.kernelParams = lib.mkIf securityConfig.hardening.kernel.enable (
      mkKernelParams securityConfig.hardening.level ++
      lib.optionals securityConfig.hardening.kernel.mitigations [
        "mitigations=auto,nosmt"
        "spectre_v2=on"
        "spec_store_bypass_disable=on"
        "l1tf=full,force"
        "mds=full,nosmt"
        "tsx=off"
        "tsx_async_abort=full,nosmt"
      ]
    );

    boot.blacklistedKernelModules = lib.mkIf securityConfig.hardening.kernel.enable (
      mkBlacklistedModules securityConfig.hardening.kernel.modules.blacklist
    );

    boot.kernel.sysctl = lib.mkIf securityConfig.hardening.kernel.enable (lib.mkMerge [
      # Convert kernel parameters to sysctl format
      (lib.listToAttrs (map (param: 
        let parts = lib.splitString "=" param; 
        in { name = lib.head parts; value = lib.last parts; }
      ) (mkKernelParams securityConfig.hardening.level)))
      
      # Additional sysctl settings
      (lib.mkIf securityConfig.hardening.network.enable {
        # Network hardening
        "net.ipv4.ip_forward" = 0;
        "net.ipv6.conf.all.forwarding" = 0;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
      })
    ]);

    # Filesystem Hardening
    fileSystems = lib.mkIf securityConfig.hardening.filesystem.enable (lib.mkMerge [
      # noexec mounts
      (lib.listToAttrs (map (mount: {
        name = mount;
        value = { options = [ "noexec" "nosuid" "nodev" ]; };
      }) securityConfig.hardening.filesystem.noexec))
      
      # hidepid
      (lib.mkIf securityConfig.hardening.filesystem.hidepid {
        "/proc" = { options = [ "hidepid=2" ]; };
      })
    ]);

    # Access Control Systems
    security.apparmor = lib.mkIf (securityConfig.accessControl.enable && securityConfig.accessControl.backend == "apparmor") {
      enable = true;
      killUnconfinedConfinables = securityConfig.accessControl.enforcing;
      profiles = mkApparmorProfiles securityConfig.accessControl.policies;
    };

    # Note: SELinux would be configured here if supported
    # security.selinux = lib.mkIf (securityConfig.accessControl.enable && securityConfig.accessControl.backend == "selinux") {
    #   enable = true;
    #   policy = if securityConfig.accessControl.enforcing then "targeted" else "permissive";
    # };

    # Security Monitoring
    security.auditd = lib.mkIf securityConfig.monitoring.auditd.enable {
      enable = true;
      rules = mkAuditRules securityConfig.monitoring.auditd.rules;
    };

    # Intrusion Detection
    environment.systemPackages = lib.mkIf securityConfig.monitoring.intrusion.enable (
      with pkgs; [
        aide  # File integrity monitoring
        lynis  # Security auditing
      ] ++ lib.optionals (securityConfig.monitoring.intrusion.backend == "aide") [
        aide
      ] ++ lib.optionals securityConfig.monitoring.intrusion.realtime [
        inotify-tools
      ]
    );

    # AIDE Configuration
    services.aide = lib.mkIf (securityConfig.monitoring.intrusion.enable && securityConfig.monitoring.intrusion.backend == "aide") {
      enable = true;
      config = ''
        # AIDE configuration
        database_in=file:@@{DBDIR}/aide.db
        database_out=file:@@{DBDIR}/aide.db.new
        database_new=file:@@{DBDIR}/aide.db.new
        gzip_dbout=yes
        verbose=5
        report_url=file:@@{LOGDIR}/aide.log
        report_url=stdout
        
        # Define groups
        BinLib = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
        ConfFiles = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
        Logs = p+i+n+u+g+s+b+m+c+md5+sha1+sha256
        
        # Rules
        /bin BinLib
        /usr/bin BinLib
        /sbin BinLib
        /usr/sbin BinLib
        /etc ConfFiles
        /var/log Logs
      '';
    };

    # Security Logging
    services.journald.extraConfig = lib.mkIf securityConfig.monitoring.logging.journald ''
      # Security event logging
      ForwardToSyslog=yes
      MaxRetentionSec=${securityConfig.monitoring.logging.retention}
      SystemMaxUse=1G
      SystemMaxFileSize=100M
    '';

    services.rsyslog = lib.mkIf securityConfig.monitoring.logging.syslog {
      enable = true;
      defaultConfig = ''
        # Security event logging
        auth,authpriv.*                 /var/log/auth.log
        *.*;auth,authpriv.none          -/var/log/syslog
        kern.*                          -/var/log/kern.log
        
        # Security alerts
        *.emerg                         :omusrmsg:*
      '';
    };

    # Encryption Services
    security.tpm2 = lib.mkIf securityConfig.encryption.tpm.enable {
      enable = true;
      pkcs11.enable = true;  # PKCS#11 interface for TPM
      tctiEnvironment.enable = true;  # TCTI environment
    };

    # TPM-based disk encryption would be configured here
    boot.initrd.luks.devices = lib.mkIf (securityConfig.encryption.diskEncryption.enable && securityConfig.encryption.tpm.enable) {
      # This would integrate TPM with LUKS
      # Implementation depends on specific requirements
    };

    # Compliance Framework Integration
    services.openssh = lib.mkIf (securityConfig.compliance.enable && lib.elem "cis" securityConfig.compliance.frameworks) 
      (mkComplianceConfig securityConfig.compliance.frameworks).services.sshd;

    # Fail2ban for additional security
    services.fail2ban = lib.mkIf (securityConfig.monitoring.intrusion.enable && securityConfig.hardening.level != "minimal") {
      enable = true;
      bantime = "1h";
      bantime-increment = {
        enable = true;
        factor = "2";
        maxtime = "168h";  # 1 week
      };
      jails = {
        ssh = ''
          enabled = true
          port = 22
          filter = sshd
          logpath = /var/log/auth.log
          maxretry = 3
          findtime = 600
        '';
      };
    };

    # Store implementation metadata
    services.security._implementation = {
      platform = "nixos";
      hardeningLevel = securityConfig.hardening.level;
      accessControlBackend = securityConfig.accessControl.backend;
      intrusionDetectionBackend = securityConfig.monitoring.intrusion.backend;
      encryptionBackends = {
        disk = securityConfig.encryption.diskEncryption.backend;
        tpm = securityConfig.encryption.tpm.enable;
        secureBoot = securityConfig.encryption.secureBoot.enable;
      };
      complianceFrameworks = securityConfig.compliance.frameworks;
      monitoringEnabled = {
        auditd = config.security.auditd.enable;
        aide = config.services.aide.enable or false;
        fail2ban = config.services.fail2ban.enable;
        logging = securityConfig.monitoring.logging.enable;
      };
    };
  };
}