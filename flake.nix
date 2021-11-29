{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    naersk.url = "github:nmattia/naersk";
    mozillapkgs = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
    rust-analyzer = {
      url = "github:grenewode/rust-analyzer-flake";
      inputs.naersk.follows = "naersk";
    };
  };

  outputs = { self, nixpkgs, flake-utils, naersk, mozillapkgs, rust-analyzer }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") { };
        channel = (mozilla.rustChannelOf {
          rustToolchain = ./rust-toolchain.toml;
          hash = pkgs.lib.fakeHash;
        });
        naersk-lib = naersk.lib."${system}".override {
          cargo = channel.rust;
          rustc = channel.rust;
        };
        defaultPackage = naersk-lib.buildPackage { root = ./.; };
        defaultPackageName = (builtins.parseDrvName defaultPackage.name).name;
      in rec {
        # `nix build`
        packages = {
          ${defaultPackageName} = defaultPackage;
        } // {
          inherit (channel) rust;
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
            channel.rust
            channel.rust-src
            self.packages.${system}.rust-analyzer
          ] ++ (with pkgs; [ pkg-config ]);
        };
      });
}
