{
  description = "Zach's Nix configuration monorepo";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      debug = true;
      systems = ["x86_64-linux"];
      imports = [./hosts];
      
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Add test checks
        checks = {
          tests = (import ./tests { 
            inherit (pkgs) lib;
            inherit pkgs; 
          }).check;
        };
      };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";

    minimal-emacs = {
      url = "github:jamescherti/minimal-emacs.d";
      flake = false;
    };
  };
}
