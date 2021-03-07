{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
rustPlatform.buildRustPackage rec {
  name = "i3switcher-${version}";
  version = "0.3.1";
  src = ./.;
  buildInputs = [ pkgs.libzip ];

  checkPhase = "";
  cargoSha256 = "sha256:1wxl3vn6sd0ak7qaaywdasli54msgf8fyqxi7hg0k6bdbnvnr76i";

  meta = with stdenv.lib; {
    description = "provides nicer behavior for workspace switching in i3";
    homepage = https://github.com/grenewode/i3switcher;
    license = licenses.isc;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
