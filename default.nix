{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/af8cd5ded7735ca1df1a1174864daab75feeb64a.tar.gz") {} }:

with pkgs;

let
  my-pkgs = rWrapper.override {
    packages = with rPackages; [
      git2r
      plumber
      desc
    ];
  };
in
mkShell {
  buildInputs = [my-pkgs nixVersions.nix_2_16];
}
