{

  nixConfig = {
    substituters = [
      "https://nix-community.cachix.org"
      "https://rust-analyzer-flake.cachix.org"
    ];

    trusted-public-keys = [
      "rust-analyzer-flake.cachix.org-1:M0/jTcCtgtFl6/aZV4l08+JN9Zf5dHzALWrKmCXeeoU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    rust-analyzer.url = "github:grenewode/rust-analyzer-flake";
  };

  outputs = { self, nixpkgs, flake-utils, rust-analyzer }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        inherit (pkgs) rustc cargo cargo-edit rustPlatform;
        inherit (pkgs.lib) readFile;
        inherit (builtins) fromTOML;

        cargoToml = fromTOML (readFile ./Cargo.toml);

        inherit (cargoToml.package) name version;
        inherit (rust-analyzer.packages.${system}) rust-analyzer-nightly;

        package = rustPlatform.buildRustPackage {
          inherit name version;

          src = ./.;
          cargoLock = {
            lockFile = ./Cargo.lock;
          };
        };
      in rec {
        # `nix build`
        packages.${name} = package;
        packages.default = package;
        defaultPackage = package;

        # `nix run`
        apps.${name} = flake-utils.lib.mkApp { drv = packages.default; };
        apps.default = apps.${name};
        defaultApp = apps.default;

        # `nix develop`
        devShell = (pkgs.mkShell {
          packages = [ rustc cargo rust-analyzer-nightly cargo-edit ]
            ++ package.buildInputs;
        });
      });
}
