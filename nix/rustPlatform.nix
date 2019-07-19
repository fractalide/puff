{ recurseIntoAttrs, stdenv, lib,
  makeRustPlatform, fetchurl, patchelf
, rustManifest ? ./channel-rust-nightly.toml
}:

let
  targets = [
    "x86_64-unknown-linux-gnu"
  ];
  rustChannel =
    lib.rustLib.fromManifestFile rustManifest {
      inherit stdenv fetchurl patchelf;
    };
  rust =
    rustChannel.rust.override {
      inherit targets;
    };
in
makeRustPlatform {
  rustc = rust;
  cargo = rust;
}
