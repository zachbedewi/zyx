# ========================================
#
# Eye Of God - Primary machine
#
# ========================================
{
  inputs,
  inputs',
  self',
  self,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    #
    # ===== Hardware =====
    #
    ./hardware-configuration.nix

    inputs.home-manager.nixosModules.home-manager
    inputs.stylix.nixosModules.stylix
    ../../../modules/options
    ../../../modules/system/nixos
    ../../../modules/system/common
  ];

  config = {
    modules = {
      device = {
        type = "laptop";
        hasAudio = true;
      };

      system = {
        audio.enable = true;
      };

      services = {
        display = {
          enable = true;
          backend = "x11";
          desktopEnvironment = "plasma";
        };
      };
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
    ];

    stylix = {
      enable = true;
      image = config.lib.stylix.pixel "base0A";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };

    home-manager = {
      backupFileExtension = "backup";
      extraSpecialArgs = {
        inherit inputs self inputs' self' pkgs;
      };

      users.skitzo.imports = [
        ../../../home
      ];
    };

    # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
    system.stateVersion = "23.11";
  };
}
