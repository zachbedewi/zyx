{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = lib.flatten [
    ../../../modules/home/xdg
    ../../../modules/home/packages
    ../../../home/starship.nix
  ];

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  services.ssh-agent.enable = true;

  home = {
    username = "skitzo";
    homeDirectory = "/home/skitzo";
    stateVersion = lib.mkDefault "24.11";
  };
}
