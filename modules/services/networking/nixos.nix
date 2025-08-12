{ lib, config, pkgs, ... }:

let
  networkConfig = config.services.networking;
  
  # Helper functions for network configuration
  mkNetworkManagerProfile = name: profile: {
    connection = {
      id = name;
      type = "wifi";
      autoconnect = profile.autoConnect;
      autoconnect-priority = profile.priority;
    };
    
    wifi = {
      ssid = profile.ssid;
      hidden = profile.hidden;
    };
    
    wifi-security = lib.optionalAttrs (profile.security != "none") {
      key-mgmt = 
        if profile.security == "wpa-psk" then "wpa-psk"
        else if profile.security == "wpa-enterprise" then "wpa-eap"
        else throw "Unsupported security type: ${profile.security}";
    };
    
    ipv4.method = "auto";
    ipv6.addr-gen-mode = "stable-privacy";
    ipv6.method = "auto";
  };

  # Generate firewall rules from custom rules
  mkFirewallRules = rules: builtins.map (rule:
    let
      protocolFlag = if rule.protocol != null && rule.protocol != "all" 
                     then "-p ${rule.protocol}" 
                     else "";
      sourceFlag = if rule.sourceAddress != null 
                   then "-s ${rule.sourceAddress}" 
                   else "";
      portFlag = if rule.destinationPort != null 
                 then "--dport ${toString rule.destinationPort}" 
                 else "";
      interfaceFlag = if rule.interface != null 
                      then "-i ${rule.interface}" 
                      else "";
      actionFlag = 
        if rule.action == "accept" then "-j ACCEPT"
        else if rule.action == "drop" then "-j DROP"
        else if rule.action == "reject" then "-j REJECT"
        else if rule.action == "log" then "-j LOG"
        else throw "Unsupported firewall action: ${rule.action}";
      
      comment = if rule.comment != null 
                then "-m comment --comment \"${rule.comment}\"" 
                else "";
    in
    "${protocolFlag} ${sourceFlag} ${portFlag} ${interfaceFlag} ${comment} ${actionFlag}"
  ) rules;

  # Generate WireGuard peer configurations
  mkWireGuardPeers = profiles: lib.mapAttrsToList (name: profile: 
    lib.optionalAttrs (profile.type == "wireguard") {
      # This would normally include peer configuration
      # For now, we create a placeholder structure
      inherit name;
      inherit (profile) autoStart killswitch routes;
    }
  ) profiles;

in {
  config = lib.mkIf (
    config.services.networking.enable && 
    config.platform.capabilities.supportsNixOS
  ) {
    
    # WiFi Management Configuration
    networking.networkmanager = lib.mkIf (networkConfig.wifi.enable && networkConfig.wifi.backend == "networkmanager") {
      enable = true;
      wifi.powersave = lib.mkDefault config.device.capabilities.isMobile;  # Enable power saving on mobile devices
      dns = "systemd-resolved";
      
      # Generate connection profiles
      profiles = lib.mapAttrs mkNetworkManagerProfile networkConfig.wifi.profiles;
      
      # Additional NetworkManager configuration
      extraConfig = ''
        [main]
        plugins=keyfile
        
        [logging]
        level=INFO
        
        [connection]
        wifi.powersave=2
      '';
    };

    networking.wpa_supplicant = lib.mkIf (networkConfig.wifi.enable && networkConfig.wifi.backend == "wpa_supplicant") {
      enable = true;
      networks = lib.mapAttrs (name: profile: {
        ssid = profile.ssid;
        psk = lib.mkIf (profile.security == "wpa-psk") "@PSK_${name}@";  # Placeholder for PSK
        hidden = profile.hidden;
        priority = profile.priority;
      }) networkConfig.wifi.profiles;
      
      extraConfig = ''
        ctrl_interface=/run/wpa_supplicant
        ctrl_interface_group=wheel
        update_config=1
      '';
    };

    networking.iwd = lib.mkIf (networkConfig.wifi.enable && networkConfig.wifi.backend == "iwd") {
      enable = true;
      settings = {
        General = {
          EnableNetworkConfiguration = true;
        };
        Network = {
          EnableIPv6 = true;
          NameResolvingService = "systemd";
        };
      };
    };

    # VPN Configuration
    networking.wireguard = lib.mkIf (networkConfig.vpn.enable && networkConfig.vpn.backend == "wireguard") {
      enable = true;
      interfaces = lib.mapAttrs (name: profile: lib.optionalAttrs (profile.type == "wireguard") {
        # Basic WireGuard interface configuration
        # In a real implementation, this would include keys, peers, etc.
        listenPort = 51820;  # Default port
        
        # Killswitch implementation
        postSetup = lib.optionalString profile.killswitch ''
          ${pkgs.iptables}/bin/iptables -I OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -j DROP
        '';
        
        postShutdown = lib.optionalString profile.killswitch ''
          ${pkgs.iptables}/bin/iptables -D OUTPUT ! -o %i -m mark ! --mark $(wg show %i fwmark) -j DROP
        '';
      }) networkConfig.vpn.profiles;
    };

    # OpenVPN configuration would go here for OpenVPN profiles
    services.openvpn.servers = lib.mkIf (networkConfig.vpn.enable && networkConfig.vpn.backend == "openvpn") (
      lib.mapAttrs (name: profile: lib.optionalAttrs (profile.type == "openvpn") {
        autoStart = profile.autoStart;
        # OpenVPN configuration would be specified here
        config = ''
          # OpenVPN configuration for ${name}
          # This would include the actual OpenVPN config
        '';
      }) networkConfig.vpn.profiles
    );

    # Firewall Configuration
    networking.firewall = lib.mkIf networkConfig.firewall.enable {
      enable = true;
      
      # Basic firewall settings
      allowedTCPPorts = networkConfig.firewall.allowedTCPPorts;
      allowedUDPPorts = networkConfig.firewall.allowedUDPPorts;
      
      allowedTCPPortRanges = builtins.map (range: {
        from = range.from;
        to = range.to;
      }) networkConfig.firewall.allowedTCPPortRanges;
      
      allowedUDPPortRanges = builtins.map (range: {
        from = range.from;
        to = range.to;
      }) networkConfig.firewall.allowedUDPPortRanges;
      
      trustedInterfaces = networkConfig.firewall.trustedInterfaces;
      
      # Custom rules via extraCommands
      extraCommands = lib.optionalString (networkConfig.firewall.customRules != []) (
        lib.concatStringsSep "\n" (mkFirewallRules networkConfig.firewall.customRules)
      );
      
      # Default policy implementation
      rejectPackets = networkConfig.firewall.defaultPolicy == "reject";
      # Note: NixOS firewall doesn't directly support "accept" default policy
      # This would need custom iptables rules for full implementation
    };

    # DNS Configuration
    services.resolved = lib.mkIf networkConfig.dns.enable {
      enable = true;
      
      dns = networkConfig.dns.servers;
      fallbackDns = networkConfig.dns.fallbackDns;
      domains = networkConfig.dns.domains;
      
      dnssec = if networkConfig.dns.dnssec then "true" else "false";
      dnsOverTls = if networkConfig.dns.dnsOverTls then "true" else "false";
      
      extraConfig = ''
        [Resolve]
        ReadEtcHosts=yes
        ResolveUnicastSingleLabel=no
      '';
    };

    # Network Monitoring
    services.vnstat = lib.mkIf (networkConfig.monitoring.enable && networkConfig.monitoring.bandwidth) {
      enable = true;
    };
    
    services.suricata = lib.mkIf (networkConfig.monitoring.enable && networkConfig.monitoring.intrusion) {
      enable = true;
      settings = {
        vars = {
          address-groups = {
            HOME_NET = "[192.168.0.0/16,10.0.0.0/8,172.16.0.0/12]";
            EXTERNAL_NET = "!$HOME_NET";
          };
        };
      };
    };

    # System packages for network management
    environment.systemPackages = with pkgs; [
      # Core networking tools
      iproute2
      ethtool
      bridge-utils
      
      # WiFi management tools (if WiFi is available)
    ] ++ lib.optionals config.device.capabilities.hasWiFi [
      iw
      wireless-tools
      wpa_supplicant
    ] ++ lib.optionals networkConfig.vpn.enable [
      # VPN tools
      wireguard-tools
    ] ++ lib.optionals (networkConfig.vpn.enable && networkConfig.vpn.backend == "openvpn") [
      openvpn
    ] ++ lib.optionals networkConfig.monitoring.enable [
      # Monitoring tools
      iftop
      nethogs
      nload
      vnstat
    ] ++ lib.optionals networkConfig.monitoring.intrusion [
      suricata
    ];

    # Store implementation metadata
    services.networking._implementation = {
      platform = "nixos";
      
      wifi = {
        backend = networkConfig.wifi.backend;
        networkManagerEnabled = config.networking.networkmanager.enable or false;
        wpaSupplicantEnabled = config.networking.wpa_supplicant.enable or false;
        iwdEnabled = config.networking.iwd.enable or false;
        profileCount = builtins.length (lib.attrNames networkConfig.wifi.profiles);
      };
      
      vpn = {
        backend = networkConfig.vpn.backend;
        wireguardEnabled = config.networking.wireguard.enable or false;
        openvpnEnabled = (config.services.openvpn.servers != {});
        profileCount = builtins.length (lib.attrNames networkConfig.vpn.profiles);
      };
      
      firewall = {
        backend = networkConfig.firewall.backend;
        nixosFirewallEnabled = config.networking.firewall.enable;
        customRulesCount = builtins.length networkConfig.firewall.customRules;
        defaultPolicy = networkConfig.firewall.defaultPolicy;
      };
      
      dns = {
        systemdResolved = config.services.resolved.enable or false;
        dnssec = networkConfig.dns.dnssec;
        dnsOverTls = networkConfig.dns.dnsOverTls;
        serverCount = builtins.length networkConfig.dns.servers;
      };
      
      monitoring = {
        bandwidth = networkConfig.monitoring.bandwidth && (config.services.vnstat.enable or false);
        intrusion = networkConfig.monitoring.intrusion && (config.services.suricata.enable or false);
        logging = networkConfig.monitoring.logging;
      };
    };

    # Enable systemd-networkd for advanced networking if needed
    systemd.network.enable = lib.mkDefault (
      networkConfig.wifi.backend == "iwd" || 
      networkConfig.vpn.enable
    );

    # Network optimization for different device types
    boot.kernel.sysctl = lib.optionalAttrs config.device.capabilities.isMobile {
      # Power saving optimizations for mobile devices
      "net.ipv4.ip_dynaddr" = 1;
      "net.ipv4.tcp_keepalive_time" = 1200;  # Reduce keepalive time to save battery
    } // lib.optionalAttrs (config.device.type == "server") {
      # Server networking optimizations
      "net.core.rmem_max" = 134217728;
      "net.core.wmem_max" = 134217728;
      "net.ipv4.tcp_rmem" = "4096 87380 134217728";
      "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      "net.ipv4.tcp_congestion_control" = "bbr";
    } // lib.optionalAttrs config.device.profiles.isDevelopment {
      # Development-friendly network settings
      "net.core.somaxconn" = 65535;
      "net.ipv4.ip_local_port_range" = "1024 65535";
    };

    # Assert proper configuration dependencies
    assertions = [
      {
        assertion = 
          networkConfig.wifi.enable -> 
          (networkConfig.wifi.backend != "auto" || config.device.capabilities.hasWiFi);
        message = "WiFi backend must be specified when WiFi is enabled without WiFi capability";
      }
      {
        assertion = 
          networkConfig.vpn.enable -> 
          (networkConfig.vpn.profiles != {} || !networkConfig.vpn.enable);
        message = "VPN service enabled but no profiles configured";
      }
      {
        assertion = 
          (networkConfig.firewall.backend == "iptables") -> 
          config.platform.capabilities.isLinux;
        message = "iptables firewall backend requires Linux platform";
      }
      {
        assertion = 
          networkConfig.dns.dnsOverTls -> 
          config.services.resolved.enable;
        message = "DNS over TLS requires systemd-resolved";
      }
    ];
  };
}