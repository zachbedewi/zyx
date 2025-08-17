{inputs}: _final: _prev: let
  zyxLib = import ../default.nix {inherit inputs;};
in {
  # Expose zyx library namespaces
  zyx = {
    filesystem = zyxLib.flake.lib.filesystem;
    builder = zyxLib.flake.lib.builder;
  };

  # Expose home-manager library namespaces
  inherit (inputs.home-manager.lib) hm;
}
