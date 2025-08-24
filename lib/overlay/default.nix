{ inputs }:
_final: _prev:
let
  zyxLib = import ../default.nix { inherit inputs; };
in
{
  # Expose zyx library namespaces
  zyx = {
    inherit (zyxLib.flake.lib) filesystem;
    inherit (zyxLib.flake.lib) builder;
  };

  # Expose home-manager library namespaces
  # This needs to be under the `hm` namespace in order to work properly
  inherit (inputs.home-manager.lib) hm;
}
