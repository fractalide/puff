{ mozillaOverlay ? import (builtins.fetchTarball https://github.com/mozilla/nixpkgs-mozilla/archive/master.tar.gz)
, rustManifest ? builtins.fetchurl "https://static.rust-lang.org/dist/channel-rust-nightly.toml"
, config ? null
, ...
}:

let
  pkgs = import <nixpkgs> { overlays = [ mozillaOverlay ]; };
in
with pkgs;
let
  rustPlatform = recurseIntoAttrs (callPackage ./rustPlatform.nix {
    inherit rustManifest;
  });
  puff = callPackage ./pkg-puff.nix { inherit rustPlatform; };
in
puff
