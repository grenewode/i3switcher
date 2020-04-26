{ pkgs ? import <nixpkgs> {}, ... }:
with pkgs;
rustPlatform.buildRustPackage rec {
  name = "i3switcher-${version}";
  version = "0.3.1";
  src = ./.;
  buildInputs = [ pkgs.libzip ];

  checkPhase = "";
  cargoSha256 = "sha256:0719871frl9yh1jzbyg39fwf8qzs4ngbsqq38rr5w9a03scqi5j6";

  meta = with stdenv.lib; {
    description = "provides nicer behavior for workspace switching in i3";
    homepage = https://github.com/grenewode/i3switcher;
    license = licenses.isc;
    maintainers = [];
    platforms = platforms.all;
  };
}
