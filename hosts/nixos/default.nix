{
  lib,
  inputs,
  inputs',
  outputs,
  self,
  self',
  ...
}: {
  flake.nixosConfigurations.eye-of-god = lib.nixosSystem {
    specialArgs = {
      inherit self self' inputs inputs' outputs lib;
    };
    modules = [./eye-of-god];
  };
}
