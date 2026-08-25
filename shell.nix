{ pkgs ? import <nixpkgs> {} }:

# some bs
pkgs.mkShell {
  packages = with pkgs; [
    alsa-lib
    libGL
    libX11
    libXi
    libXcursor
  ];
}
