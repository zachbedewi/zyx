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
  ];

  programs.zsh.enable = true;

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

  programs.git.enable = true;

  users.users.root = {
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs self inputs' self' pkgs;
    };

    users.skitzo.imports = [
      ../../../home
    ];
  };

  # https://wiki.nixos.org/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.11";
}
