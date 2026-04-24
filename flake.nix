{
  description = "Home Manager modules and packages for Gas City (gc) and Beads (bd)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
    in
    # Per-system outputs (packages).
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = rec {
          gascity = pkgs.callPackage ./pkgs/gascity { };
          beads = pkgs.callPackage ./pkgs/beads { };
          default = gascity;
        };
      }
    )
    //
    # System-agnostic outputs (overlays + home-manager modules).
    {
      overlays.default = import ./overlays/default.nix;

      homeManagerModules = {
        gascity = import ./modules/gascity.nix;
        beads = import ./modules/beads.nix;
        default = {
          imports = [
            ./modules/gascity.nix
            ./modules/beads.nix
          ];
        };
      };
    };
}
