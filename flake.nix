{
  description = "Zach's Nix configuration monorepo";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
