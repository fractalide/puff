{ nixpkgs ? fetchTarball channel:nixos-unstable
, pkgs ? import nixpkgs {}
}:

with pkgs;

stdenv.mkDerivation {
  name = "jolt";
  src = null;
  buildInputs = [ rustup pkgconfig openssl cargo-web ];
}
