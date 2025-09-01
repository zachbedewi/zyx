{
  lib,
  username,
  ...
}:
{
  imports = [
    ../../../modules/home/xdg
    ../../../modules/home/packages
    ../../../home/starship.nix
  ];

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;

  services.ssh-agent.enable = true;

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = lib.mkDefault "24.11";
  };
}
