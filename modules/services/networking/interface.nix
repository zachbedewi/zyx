{ lib, config, pkgs, ... }:

{
  options.services.networking = {
    enable = lib.mkOption {
      type = lib.types.bool;
      description = "Enable network management services";
      default = config.device.capabilities.hasNetworking;
    };

    wifi = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable WiFi management";
        default = config.device.capabilities.hasWiFi;
      };

      backend = lib.mkOption {
        type = lib.types.enum [ "networkmanager" "wpa_supplicant" "iwd" "auto" ];
        description = "WiFi management backend";
        default = "auto";
      };

      profiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            ssid = lib.mkOption {
              type = lib.types.str;
              description = "Network SSID";
            };

            priority = lib.mkOption {
              type = lib.types.int;
              description = "Connection priority (higher = preferred)";
              default = 1;
            };

            security = lib.mkOption {
              type = lib.types.enum [ "none" "wep" "wpa-psk" "wpa-enterprise" ];
              description = "Security type";
              default = "wpa-psk";
            };

            hidden = lib.mkOption {
              type = lib.types.bool;
              description = "Whether this is a hidden network";
              default = false;
            };

            autoConnect = lib.mkOption {
              type = lib.types.bool;
              description = "Automatically connect to this network";
              default = true;
            };
          };
        });
        description = "WiFi connection profiles";
        default = {};
      };
    };

    vpn = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable VPN services";
        default = false;
      };

      backend = lib.mkOption {
        type = lib.types.enum [ "wireguard" "openvpn" "auto" ];
        description = "VPN backend to use";
        default = "auto";
      };

      profiles = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            type = lib.mkOption {
              type = lib.types.enum [ "wireguard" "openvpn" ];
              description = "VPN protocol type";
            };

            autoStart = lib.mkOption {
              type = lib.types.bool;
              description = "Start VPN automatically on boot";
              default = false;
            };

            killswitch = lib.mkOption {
              type = lib.types.bool;
              description = "Enable VPN killswitch (block traffic when VPN is down)";
              default = false;
            };

            routes = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Custom routes for this VPN";
              default = [];
            };
          };
        });
        description = "VPN connection profiles";
        default = {};
      };
    };

    firewall = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable firewall";
        default = true;
      };

      backend = lib.mkOption {
        type = lib.types.enum [ "iptables" "nftables" "pf" "auto" ];
        description = "Firewall backend";
        default = "auto";
      };

      defaultPolicy = lib.mkOption {
        type = lib.types.enum [ "drop" "reject" "accept" ];
        description = "Default policy for unmatched traffic";
        default = "drop";
      };

      allowedTCPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        description = "Allowed TCP ports";
        default = [];
      };

      allowedUDPPorts = lib.mkOption {
        type = lib.types.listOf lib.types.port;
        description = "Allowed UDP ports";
        default = [];
      };

      allowedTCPPortRanges = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.port;
              description = "Start of port range";
            };
            to = lib.mkOption {
              type = lib.types.port;
              description = "End of port range";
            };
          };
        });
        description = "Allowed TCP port ranges";
        default = [];
      };

      allowedUDPPortRanges = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            from = lib.mkOption {
              type = lib.types.port;
              description = "Start of port range";
            };
            to = lib.mkOption {
              type = lib.types.port;
              description = "End of port range";
            };
          };
        });
        description = "Allowed UDP port ranges";
        default = [];
      };

      trustedInterfaces = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Trusted network interfaces";
        default = [ "lo" ];
      };

      customRules = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            action = lib.mkOption {
              type = lib.types.enum [ "accept" "drop" "reject" "log" ];
              description = "Action to take";
            };

            protocol = lib.mkOption {
              type = lib.types.nullOr (lib.types.enum [ "tcp" "udp" "icmp" "all" ]);
              description = "Protocol to match";
              default = null;
            };

            sourceAddress = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Source IP address or CIDR";
              default = null;
            };

            destinationPort = lib.mkOption {
              type = lib.types.nullOr lib.types.port;
              description = "Destination port";
              default = null;
            };

            interface = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Network interface";
              default = null;
            };

            comment = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              description = "Rule comment";
              default = null;
            };
          };
        });
        description = "Custom firewall rules";
        default = [];
      };
    };

    dns = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable DNS management";
        default = true;
      };

      servers = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "DNS servers";
        default = [ "1.1.1.1" "8.8.8.8" ];
      };

      fallbackDns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Fallback DNS servers";
        default = [ "9.9.9.9" "8.8.4.4" ];
      };

      dnssec = lib.mkOption {
        type = lib.types.bool;
        description = "Enable DNSSEC validation";
        default = true;
      };

      dnsOverTls = lib.mkOption {
        type = lib.types.bool;
        description = "Use DNS over TLS";
        default = false;
      };

      domains = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Search domains";
        default = [];
      };
    };

    monitoring = {
      enable = lib.mkOption {
        type = lib.types.bool;
        description = "Enable network monitoring";
        default = config.device.profiles.isDevelopment;
      };

      bandwidth = lib.mkOption {
        type = lib.types.bool;
        description = "Monitor bandwidth usage";
        default = config.services.networking.monitoring.enable;
      };

      intrusion = lib.mkOption {
        type = lib.types.bool;
        description = "Enable intrusion detection";
        default = config.device.profiles.isWorkstation;
      };

      logging = lib.mkOption {
        type = lib.types.bool;
        description = "Enable network connection logging";
        default = config.services.networking.monitoring.enable;
      };
    };

    # Internal implementation details
    _implementation = lib.mkOption {
      type = lib.types.attrs;
      description = "Platform-specific network implementation details";
      internal = true;
      default = {};
    };
  };

  config = lib.mkIf config.services.networking.enable {
    # Capability assertions
    assertions = [
      {
        assertion = config.device.capabilities.hasNetworking;
        message = "Network services require networking capability";
      }
      {
        assertion = config.services.networking.wifi.enable -> config.device.capabilities.hasWiFi;
        message = "WiFi service requires WiFi capability";
      }
      {
        assertion = config.services.networking.vpn.enable -> config.device.capabilities.hasNetworking;
        message = "VPN service requires networking capability";
      }
      {
        assertion = 
          let hasWifiProfiles = config.services.networking.wifi.profiles != {};
          in config.services.networking.wifi.enable -> hasWifiProfiles || !config.device.capabilities.hasWiFi;
        message = "WiFi service enabled but no profiles configured on WiFi-capable device";
      }
    ];

    # Auto-select backends based on platform capabilities
    services.networking.wifi.backend = lib.mkDefault (
      if config.platform.capabilities.isDarwin then "auto"  # macOS uses built-in WiFi management
      else if config.device.profiles.isWorkstation then "networkmanager"
      else "wpa_supplicant"
    );

    services.networking.vpn.backend = lib.mkDefault "wireguard";

    services.networking.firewall.backend = lib.mkDefault (
      if config.platform.capabilities.isDarwin then "pf"
      else "iptables"
    );

    # Add common network tools based on capabilities
    environment.systemPackages = lib.optionals config.platform.capabilities.supportsNixOS [
      # Network diagnostics
      pkgs.ping
      pkgs.traceroute
      pkgs.nmap
      pkgs.netcat-gnu
      
      # WiFi tools (if WiFi is available)
    ] ++ lib.optionals (config.device.capabilities.hasWiFi && config.platform.capabilities.supportsNixOS) [
      pkgs.iw
      pkgs.wireless-tools
    ] ++ lib.optionals (config.services.networking.monitoring.enable && config.platform.capabilities.supportsNixOS) [
      pkgs.iftop
      pkgs.nethogs
      pkgs.tcpdump
    ];
  };
}