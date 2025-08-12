{ lib, pkgs }:

let
  testUtils = import ../../lib/test-utils.nix { inherit lib pkgs; };
  
  # Import the modules under test
  networkInterface = ../../../modules/services/networking/interface.nix;
  networkNixos = ../../../modules/services/networking/nixos.nix;
  platformDetection = ../../../modules/platform/detection.nix;
  platformCapabilities = ../../../modules/platform/capabilities.nix;
  
  testConfig = modules: (testUtils.evalConfig modules).config;
  
  # Base test configuration
  baseConfig = {
    device = {
      type = "laptop";
      capabilities = {
        hasNetworking = true;
        hasWiFi = true;
      };
    };
  };

  # Mock hardware configurations
  desktopConfig = {
    device = {
      type = "desktop";
      capabilities = {
        hasNetworking = true;
        hasWiFi = false;  # Desktop typically uses wired
      };
    };
  };

  serverConfig = {
    device = {
      type = "server";
      capabilities = {
        hasNetworking = true;
        hasWiFi = false;
        hasGUI = false;
      };
    };
  };

  # Test WiFi profiles
  wifiProfiles = {
    "home-network" = {
      ssid = "MyHomeWiFi";
      security = "wpa-psk";
      priority = 10;
      autoConnect = true;
    };
    
    "work-network" = {
      ssid = "CompanyWiFi";
      security = "wpa-enterprise";
      priority = 5;
      autoConnect = true;
    };
    
    "guest-network" = {
      ssid = "GuestNetwork";
      security = "none";
      priority = 1;
      autoConnect = false;
    };
  };

  # Test VPN profiles
  vpnProfiles = {
    "home-vpn" = {
      type = "wireguard";
      autoStart = false;
      killswitch = true;
      routes = [ "192.168.1.0/24" ];
    };
    
    "work-vpn" = {
      type = "openvpn";
      autoStart = true;
      killswitch = false;
      routes = [ "10.0.0.0/8" ];
    };
  };

  # Test firewall rules (with null fields for complete module specification)
  firewallRules = [
    {
      action = "accept";
      protocol = "tcp";
      destinationPort = 22;
      sourceAddress = null;
      interface = null;
      comment = "SSH access";
    }
    {
      action = "drop";
      protocol = "tcp";
      sourceAddress = "192.168.1.100";
      destinationPort = null;
      interface = null;
      comment = "Block specific IP";
    }
    {
      action = "log";
      protocol = "udp";
      interface = "wlan0";
      sourceAddress = null;
      destinationPort = null;
      comment = "Log WiFi UDP traffic";
    }
  ];

in {
  name = "networking-service";
  tests = [
    # Basic network service tests
    {
      name = "network-service-defaults-enabled-with-networking-capability";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.enable;
      expected = true;
    }

    {
      name = "network-service-disabled-without-networking-capability";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        { device.type = "vm"; device.capabilities.hasNetworking = false; }
      ]).services.networking.enable;
      expected = false;
    }

    # WiFi service tests
    {
      name = "wifi-service-defaults-enabled-with-wifi-capability";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.wifi.enable;
      expected = true;
    }

    {
      name = "wifi-service-disabled-without-wifi-capability";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        desktopConfig
      ]).services.networking.wifi.enable;
      expected = false;
    }

    {
      name = "wifi-backend-auto-selection-workstation";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.wifi.backend;
      expected = "networkmanager";  # Workstation default
    }

    {
      name = "wifi-backend-manual-override";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.wifi.backend = "iwd"; }
      ]).services.networking.wifi.backend;
      expected = "iwd";
    }

    {
      name = "wifi-profiles-configuration";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.wifi.profiles = wifiProfiles; }
      ]).services.networking.wifi.profiles."home-network".ssid;
      expected = "MyHomeWiFi";
    }

    {
      name = "wifi-profile-priority-configuration";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.wifi.profiles = wifiProfiles; }
      ]).services.networking.wifi.profiles."home-network".priority;
      expected = 10;
    }

    # VPN service tests
    {
      name = "vpn-service-disabled-by-default";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.vpn.enable;
      expected = false;
    }

    {
      name = "vpn-backend-auto-selection";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.vpn.enable = true; }
      ]).services.networking.vpn.backend;
      expected = "wireguard";  # Defaults to WireGuard
    }

    {
      name = "vpn-profiles-configuration";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.vpn = {
            enable = true;
            profiles = vpnProfiles;
          };
        }
      ]).services.networking.vpn.profiles."home-vpn".type;
      expected = "wireguard";
    }

    {
      name = "vpn-killswitch-configuration";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.vpn = {
            enable = true;
            profiles = vpnProfiles;
          };
        }
      ]).services.networking.vpn.profiles."home-vpn".killswitch;
      expected = true;
    }

    # Firewall service tests
    {
      name = "firewall-enabled-by-default";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.firewall.enable;
      expected = true;
    }

    {
      name = "firewall-backend-auto-selection-linux";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.firewall.backend;
      expected = "iptables";  # Linux default
    }

    {
      name = "firewall-default-policy";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.firewall.defaultPolicy;
      expected = "drop";
    }

    {
      name = "firewall-allowed-ports";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.firewall.allowedTCPPorts = [ 22 80 443 ]; }
      ]).services.networking.firewall.allowedTCPPorts;
      expected = [ 22 80 443 ];
    }

    {
      name = "firewall-trusted-interfaces";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.firewall.trustedInterfaces;
      expected = [ "lo" ];  # Loopback always trusted
    }

    {
      name = "firewall-custom-rules";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.firewall.customRules = firewallRules; }
      ]).services.networking.firewall.customRules;
      expected = firewallRules;
    }

    # DNS service tests
    {
      name = "dns-service-enabled-by-default";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.dns.enable;
      expected = true;
    }

    {
      name = "dns-default-servers";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.dns.servers;
      expected = [ "1.1.1.1" "8.8.8.8" ];
    }

    {
      name = "dns-fallback-servers";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.dns.fallbackDns;
      expected = [ "9.9.9.9" "8.8.4.4" ];
    }

    {
      name = "dns-dnssec-enabled-by-default";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.dns.dnssec;
      expected = true;
    }

    {
      name = "dns-over-tls-disabled-by-default";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.dns.dnsOverTls;
      expected = false;
    }

    # Network monitoring tests
    {
      name = "monitoring-enabled-for-development-profile";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.monitoring.enable;
      expected = true;  # Laptop should have isDevelopment = true
    }

    {
      name = "monitoring-disabled-for-server";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        serverConfig
      ]).services.networking.monitoring.enable;
      expected = false;  # Server doesn't have isDevelopment = true
    }

    {
      name = "bandwidth-monitoring-follows-monitoring-enable";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.monitoring.bandwidth;
      expected = true;
    }

    {
      name = "intrusion-detection-for-workstation";
      expr = (testConfig [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
      ]).services.networking.monitoring.intrusion;
      expected = true;  # Laptop should have isWorkstation = true
    }

    # NixOS implementation tests
    {
      name = "nixos-implementation-wifi-networkmanager";
      expr = (testConfig [
        networkInterface
        networkNixos
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.wifi.backend = "networkmanager"; }
      ]).services.networking._implementation.wifi.backend;
      expected = "networkmanager";
    }

    {
      name = "nixos-implementation-vpn-wireguard";
      expr = (testConfig [
        networkInterface
        networkNixos
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.vpn = {
            enable = true;
            backend = "wireguard";
          };
        }
      ]).services.networking._implementation.vpn.backend;
      expected = "wireguard";
    }

    {
      name = "nixos-implementation-firewall-iptables";
      expr = (testConfig [
        networkInterface
        networkNixos
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.firewall.backend = "iptables"; }
      ]).services.networking._implementation.firewall.backend;
      expected = "iptables";
    }

    # Assertion tests
    {
      name = "wifi-service-fails-without-wifi-capability";
      expr = testUtils.assertionShouldFail [
        networkInterface
        platformDetection
        platformCapabilities
        { device.type = "server"; device.capabilities.hasWiFi = false; }
        { services.networking.wifi.enable = true; }
      ];
      expected = true;
    }

    {
      name = "network-service-fails-without-networking-capability";
      expr = testUtils.assertionShouldFail [
        networkInterface
        platformDetection
        platformCapabilities
        { device.type = "vm"; device.capabilities.hasNetworking = false; }
        { services.networking.enable = true; }
      ];
      expected = true;
    }

    {
      name = "wifi-profiles-required-assertion";
      expr = testUtils.assertionShouldFail [
        networkInterface
        platformDetection
        platformCapabilities
        baseConfig
        { services.networking.wifi = {
            enable = true;
            profiles = {};  # Empty profiles on WiFi-capable device
          };
        }
      ];
      expected = true;
    }

    # System package tests (simplified to avoid environment.systemPackages dependency)
    {
      name = "network-tools-configured-for-nixos";
      expr = let
        config = testConfig [
          networkInterface
          platformDetection
          platformCapabilities
          baseConfig
        ];
      in config.platform.capabilities.supportsNixOS && config.services.networking.enable;
      expected = true;
    }

    {
      name = "wifi-tools-needed-with-wifi-capability";
      expr = let
        config = testConfig [
          networkInterface
          platformDetection
          platformCapabilities
          baseConfig
        ];
      in config.device.capabilities.hasWiFi && config.services.networking.wifi.enable;
      expected = true;
    }

    {
      name = "monitoring-enabled-when-development-profile-active";
      expr = let
        config = testConfig [
          networkInterface
          platformDetection
          platformCapabilities
          baseConfig
        ];
      in config.device.profiles.isDevelopment && config.services.networking.monitoring.enable;
      expected = true;
    }

    # Integration tests
    {
      name = "complete-wifi-configuration";
      expr = let
        config = testConfig [
          networkInterface
          networkNixos
          platformDetection
          platformCapabilities
          baseConfig
          {
            services.networking = {
              enable = true;
              wifi = {
                enable = true;
                backend = "networkmanager";
                profiles = wifiProfiles;
              };
            };
          }
        ];
      in {
        serviceEnabled = config.services.networking.enable;
        wifiEnabled = config.services.networking.wifi.enable;
        backend = config.services.networking.wifi.backend;
        profileCount = builtins.length (lib.attrNames config.services.networking.wifi.profiles);
      };
      expected = {
        serviceEnabled = true;
        wifiEnabled = true;
        backend = "networkmanager";
        profileCount = 3;
      };
    }

    {
      name = "complete-vpn-configuration";
      expr = let
        config = testConfig [
          networkInterface
          networkNixos
          platformDetection
          platformCapabilities
          baseConfig
          {
            services.networking = {
              enable = true;
              vpn = {
                enable = true;
                backend = "wireguard";
                profiles = vpnProfiles;
              };
            };
          }
        ];
      in {
        serviceEnabled = config.services.networking.enable;
        vpnEnabled = config.services.networking.vpn.enable;
        backend = config.services.networking.vpn.backend;
        profileCount = builtins.length (lib.attrNames config.services.networking.vpn.profiles);
      };
      expected = {
        serviceEnabled = true;
        vpnEnabled = true;
        backend = "wireguard";
        profileCount = 2;
      };
    }

    {
      name = "complete-firewall-configuration";
      expr = let
        config = testConfig [
          networkInterface
          networkNixos
          platformDetection
          platformCapabilities
          baseConfig
          {
            services.networking = {
              enable = true;
              firewall = {
                enable = true;
                backend = "iptables";
                allowedTCPPorts = [ 22 80 443 ];
                allowedUDPPorts = [ 53 ];
                customRules = firewallRules;
              };
            };
          }
        ];
      in {
        serviceEnabled = config.services.networking.enable;
        firewallEnabled = config.services.networking.firewall.enable;
        backend = config.services.networking.firewall.backend;
        tcpPorts = config.services.networking.firewall.allowedTCPPorts;
        udpPorts = config.services.networking.firewall.allowedUDPPorts;
        customRuleCount = builtins.length config.services.networking.firewall.customRules;
      };
      expected = {
        serviceEnabled = true;
        firewallEnabled = true;
        backend = "iptables";
        tcpPorts = [ 22 80 443 ];
        udpPorts = [ 53 ];
        customRuleCount = 3;
      };
    }
  ];
}