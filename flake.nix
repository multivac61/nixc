{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }@inputs:
    let
      inherit (self) outputs;
      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-linux"
        "i686-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      # Your custom packages
      # Acessible through 'nix build', 'nix shell', etc
      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./pkgs { inherit pkgs; }
      );
      # Devshell for bootstrapping
      # Acessible through 'nix develop' or 'nix-shell' (legacy)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in import ./shell.nix { inherit pkgs; }
      );

      # Your custom packages and modifications, exported as overlays
      overlays = import ./overlays { inherit inputs; };
      # Reusable nixos modules you might want to export
      # These are usually stuff you would upstream into nixpkgs
      nixosModules = import ./modules/nixos;
      # Reusable home-manager modules you might want to export
      # These are usually stuff you would upstream into home-manager
      homeManagerModules = import ./modules/home-manager;

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # FIXME replace with your hostname
        o = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs; };
          modules = [
            ./nixos/configuration.nix
            ({ modulesPath, ... }: {
              imports = [
                (modulesPath + "/installer/scan/not-detected.nix")
                (modulesPath + "/profiles/qemu-guest.nix")
                disko.nixosModules.disko
              ];
              disko.devices = {
                disk = {
                  vda = {
                    device = "/dev/vda";
                    type = "disk";
                    content = {
                      type = "gpt";
                      partitions = {
                        ESP = {
                          size = "100M";
                          type = "EF00";
                          content = {
                            type = "filesystem";
                            format = "vfat";
                            mountpoint = "/boot";
                          };
                        };
                        root = {
                          end = "-8G";
                          content = {
                            type = "filesystem";
                            format = "ext4";
                            mountpoint = "/";
                          };
                        };
                        swap = {
                          size = "100%";
                          content = {
                            type = "swap";
                            randomEncryption = true;
                            resumeDevice = true; # resume from hiberation from this device
                          };
                        };
                      };
                    };
                  };
                };
              };
              boot.loader.grub = {
                devices = [ "/dev/vda" ];
                efiSupport = true;
                efiInstallAsRemovable = true;
              };
              services.openssh.enable = true;

              users.users.root.openssh.authorizedKeys.keys = [
                # change this to your ssh key
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINNz3qigZrP1TDsPEkg+qGtvGrkZTEw0PMjj9d3MbcDS olafur@olafurs-mbp.lan"
              ];
            })
          ];

        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "o@o" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            # > Our main home-manager configuration file <
            ./home-manager/home.nix
          ];
        };
      };
    };
}
