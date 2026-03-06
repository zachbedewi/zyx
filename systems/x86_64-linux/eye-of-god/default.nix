{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  config = {
    zyx = {
      profiles = {
        development.enable = true;
        gaming.enable = true;
        workstation.enable = true;
      };
      security = {
        sops.enable = true;
      };
    };

    # Display/desktop configuration is now user-specific via homes/*/desktop.nix

    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = true;
      timeout = 3;
    };

    boot.initrd = {
      systemd.enable = true;
    };

    # Enable networking
    networking = {
      networkmanager.enable = true;
      enableIPv6 = false;
    };

    services.ntp.enable = true;
    services.automatic-timezoned.enable = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      prusa-slicer
      orca-slicer
      firefox
      neovim
      claude-code
      gcc
      ripgrep
      coreutils
      fd
      clang
      tree
      vscodium
      mcp-nixos
    ];

    stylix = {
      enable = true;
      image = config.lib.stylix.pixel "base0A";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };

    system.stateVersion = "23.11";
  };
}
