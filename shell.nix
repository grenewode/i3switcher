let
  moz_overlay = import (builtins.fetchGit {
    url = "https://github.com/mozilla/nixpkgs-mozilla.git";
    ref = "master";
  });
  nixpkgs = import <nixpkgs> { overlays = [ moz_overlay ]; };
  ruststable = (nixpkgs.latest.rustChannels.stable.rust.override {
    extensions = [
      "rust-src"
      "rls-preview"
      "rust-analysis"
      "rustfmt-preview"
      "clippy-preview"
    ];
  });
  unstable = import (fetchTarball
    "https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz")
    { };
in with nixpkgs;
stdenv.mkDerivation {
  name = "rust";
  buildInputs =
    [ unstable.rust-analyzer ruststable rls clippy rustup openssl pkg-config ];
}

