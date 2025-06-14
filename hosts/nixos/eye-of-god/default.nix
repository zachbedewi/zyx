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
  ];

  config = {
    modules.device = {
      type = "laptop";
    };

    programs.zsh.enable = true;

    nix = {
      settings = {
        experimental-features = ["nix-command" "flakes"];
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

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    services.ntp.enable = true;
    services.automatic-timezoned.enable = true;

    # Enable the KDE Plasma Desktop Environment.
    services.xserver.displayManager.sddm.enable = true;
    services.xserver.desktopManager.plasma5.enable = true;

    # Configure keymap in X11
    services.xserver = {
      layout = "us";
      xkbVariant = "";
    };

    # Enable automatic login for the user.
    services.xserver.displayManager.autoLogin.enable = true;
    services.xserver.displayManager.autoLogin.user = "skitzo";

    environment.systemPackages = with pkgs; [
      firefox
      alejandra
      neovim
      statix
      deadnix
    ];

    users.users.skitzo = {
      name = "skitzo";
      shell = pkgs.zsh;
      home = "/home/skitzo";
      isNormalUser = true;

      extraGroups = [
        "wheel"
        "audio"
        "video"
        "git"
        "networkmanager"
      ];
    };

    stylix = {
      enable = true;
      image = config.lib.stylix.pixel "base0A";
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    };

    programs.git.enable = true;

    users.users.root = {
      shell = pkgs.zsh;
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
