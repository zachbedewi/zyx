{
  config,
  lib,
  ...
}: {
  imports = lib.flatten [
    ./terminal/shells/zsh
    ./starship.nix
  ];

  services.ssh-agent.enable = true;

  home = {
    username = "skitzo";
    homeDirectory = "/home/skitzo";
    stateVersion = lib.mkDefault "24.11";
  };
}
