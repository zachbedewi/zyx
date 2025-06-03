{
  config,
  lib,
  ...
}: {
  imports = lib.flatten [
    ../modules/home/xdg
    ../modules/home/packages
    ./starship.nix
  ];

  services.ssh-agent.enable = true;

  home = {
    username = "skitzo";
    homeDirectory = "/home/skitzo";
    stateVersion = lib.mkDefault "24.11";
  };
}
