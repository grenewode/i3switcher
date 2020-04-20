{
  system ? builtins.currentSystem,
  nixpkgsMozilla ? builtins.fetchGit {
    url = https://github.com/mozilla/nixpkgs-mozilla;
    rev = "50bae918794d3c283aeb335b209efd71e75e3954";
  },
  cargo2nix ? builtins.fetchGit {
    url = https://github.com/tenx-tech/cargo2nix;
    ref = "v0.8.2";
  },
}: let
  rustOverlay = import "${nixpkgsMozilla}/rust-overlay.nix";
  cargo2nixOverlay = import "${cargo2nix}/overlay";

  pkgs = import <nixpkgs> {
    inherit system;
    overlays = [ rustOverlay cargo2nixOverlay ];
  };

  rustPkgs = pkgs.rustBuilder.makePackageSet' {
    rustChannel = "stable";
    packageFun = import ./Cargo.nix;
    # packageOverrides = pkgs: pkgs.rustBuilder.overrides.all; # Implied, if unspecified
  };
in
  rustPkgs.workspace.i3switcher {}
