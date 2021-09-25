{
  description = "A very basic flake";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";

    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , naersk
    }:
      with flake-utils.lib;
      eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          # Override the version used in naersk
          naersk-lib = naersk.lib."${system}";
        in
        rec {
          packages.i3switcher = naersk-lib.buildPackage ./.;
          defaultPackage = packages.i3switcher;
          apps.i3switcher = mkApp { drv = packages.i3switcher; };
          defaultApp = apps.i3switcher;

          devShell = pkgs.mkShell { nativeBuildInputs = with pkgs; [ rustc cargo ]; };
        }
      );
}
