{
  description = "Zach's Nix configuration monorepo";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;
      systems = ["x86_64-linux"];
      imports = [ ./hosts ];
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
    	url = "github:nix-community/home-manager/release-24.11";
    	inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
