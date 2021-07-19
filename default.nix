{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
rustPlatform.buildRustPackage rec {
  name = "i3switcher-${version}";
  version = "0.3.1";
  src = ./.;
  buildInputs = [ pkgs.libzip ];

  checkPhase = "";
  cargoSha256 = "sha256:0ckscb2vrykzcpxib4mq2b40hf0xa80ix7n3v80nfdcbm9d0zwfi";

  meta = with stdenv.lib; {
    description = "provides nicer behavior for workspace switching in i3";
    homepage = https://github.com/grenewode/i3switcher;
    license = licenses.isc;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
