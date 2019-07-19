{ stdenv, lib, rustPlatform, fetchFromGitHub, cacert, git, cargo-vendor
, openssl, pkgconfig }:

with rustPlatform;
let
  sha256 = "0wx2i7by5wbpgc1ldjaj38rbg08fcikbg038a642kwdgmj40jbxz";
  fetchcargo = import ./fetchcargo.nix {
    inherit stdenv cacert git cargo-vendor;
    inherit (rust) cargo;
  };
  puffSrc = ../.;
  puffDeps = fetchcargo {
    name = "puffDeps";
    src = puffSrc;
    inherit sha256;
  };
  jolt-deploy = fetchFromGitHub {
    owner = "carbonideltd";
    repo = "jolt-deploy";
    rev = "495de70720cc1f0b5b0ea854042ffc97768774e3";
    sha256 = "00v119qysh3cin36hb4pr5kk9976wh37wvjjmbgwl0v4r85p4g05";
  };
in

buildRustPackage rec {
  name = "puff";
  version = "0.1.0";

  src = puffSrc;
  cargoSha256 = sha256;

  buildInputs = [ puffDeps openssl pkgconfig ];
  patchPhase = ''
  mkdir .cargo
  cat >> .cargo/config <<EOF

  [source.crates-io]
  replace-with = "vendored-sources"

  [source.vendored-sources]
  directory = "${puffDeps}"
  EOF
  '';

  buildPhase = ''
    export CARGO_HOME=$(mktemp -d cargo-home.XXX)
    cargo build --release
  '';

  checkPhase = ''
    cargo test;
  '';

  doCheck = false;

  installPhase = ''
    mkdir -p $out/static
    mkdir -p $out/bin
    cp static/favicon.ico $out/static/favicon.ico
    ln -s ${jolt-deploy}/deploy $out/static/jolt
    cp static/404.html $out/static/404.html
    cp target/release/puff $out/bin/puff
  '';
}
