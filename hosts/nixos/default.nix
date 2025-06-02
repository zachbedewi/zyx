{
  lib,
  inputs,
  inputs',
  outputs,
  ...
}: {
	flake.nixosConfigurations.eye-of-god = 
		lib.nixosSystem {
			specialArgs = {
				inherit inputs inputs' outputs lib;
			};
			modules = [ ./eye-of-god ];
		};
}
