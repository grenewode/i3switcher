{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-analyzer = {
      url = "github:grenewode/rust-analyzer-flake";
      inputs.naersk.follows = "naersk";
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, rust-overlay, rust-analyzer }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlay ];
        };
        rust = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        naersk-lib = naersk.lib."${system}".override {
          cargo = rust;
          rustc = rust;
        };
        defaultPackage = naersk-lib.buildPackage { root = ./.; };
        defaultPackageName = (builtins.parseDrvName defaultPackage.name).name;
      in rec {
        # `nix build`
        packages = {
          ${defaultPackageName} = defaultPackage;
        } // {
          inherit (rust-analyzer.packages.${system}) rust-analyzer;
        };
        inherit defaultPackage;

        # `nix run`
        apps =
          builtins.mapAttrs (name: drv: flake-utils.lib.mkApp { inherit drv; });
        defaultApp = flake-utils.lib.mkApp { drv = defaultPackage; };

        # `nix develop`
        devShell = pkgs.mkShell {
          buildInputs = (with pkgs; [ openssl ]);
          nativeBuildInputs = [
            (rust.override {
              extensions = [ "rust-src" "clippy-preview" "rustfmt-preview" ];
            })
            self.packages.${system}.rust-analyzer
          ] ++ (with pkgs; [ pkg-config ]);
        };
      });
}
