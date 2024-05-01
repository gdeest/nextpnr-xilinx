{
  description = "Support for Xilinx FPGAs in nextpnr";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    openxc7.url = "github:openXC7/toolchain-nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, openxc7, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        openxc7-packages = openxc7.packages.${system};
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "nextpnr-xilinx";
          version = "0.7.0";

          src = self;

          nativeBuildInputs = [ pkgs.cmake pkgs.git ];
          buildInputs =
            [ pkgs.python310Packages.boost pkgs.python310 pkgs.eigen  pkgs.llvmPackages.openmp];
            # FIXME: It seems that we _need_ to import OpenMP unconditionally
            # here, but it does not make sense to me as OpenMP is part of the
            # GCC runtime.
            #
            # It seems that we are building with clang 16, so I don't understand
            # why the following fails: ++ (pkgs.lib.optional
            # pkgs.stdenv.cc.isClang [ pkgs.llvmPackages.openmp ]);

          cmakeFlags = [
            "-DCURRENT_GIT_VERSION=${pkgs.lib.substring 0 7 self.rev}"
            "-DARCH=xilinx"
            "-DBUILD_GUI=OFF"
            "-DBUILD_TESTS=ON"
            "-DUSE_OPENMP=ON"
            "-Wno-deprecated"
          ];

          installPhase = ''
            mkdir -p $out/bin
            cp nextpnr-xilinx bbasm $out/bin/
            mkdir -p $out/share/nextpnr/external
            cp -rv ../xilinx/external/prjxray-db $out/share/nextpnr/external/
            cp -rv ../xilinx/external/nextpnr-xilinx-meta $out/share/nextpnr/external/
            cp -rv ../xilinx/python/ $out/share/nextpnr/python/
            cp ../xilinx/constids.inc $out/share/nextpnr
          '';

          meta = with pkgs.lib; {
            description = "Place and route tool for FPGAs";
            homepage = "https://github.com/openXC7/nextpnr-xilinx";
            license = licenses.isc;
            platforms = platforms.all;
          };
        };

        # packages.arty-example
      });
}
