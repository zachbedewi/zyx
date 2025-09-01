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

    services = {
      xserver.enable = true;
      displayManager = {
        sddm.enable = true;
        autoLogin = {
          enable = true;
          user = config.modules.user.primaryUser or "skitzo";
        };
      };
      xserver.desktopManager.plasma5.enable = true;
    };

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
      firefox
      alejandra
      neovim
      statix
      deadnix
      claude-code
      nil
      gcc
      libsForQt5.kdenlive
      ripgrep
      coreutils
      fd
      clang
      tree
      nixfmt-rfc-style
    ];

    stylix = {
      enable = true;
      image = config.lib.stylix.pixel "base0A";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };

    system.stateVersion = "23.11";
  };
}
