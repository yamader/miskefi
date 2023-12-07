{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        inherit (nixpkgs) lib;
        pkgs = nixpkgs.legacyPackages.${system};
        ovmf = pkgs.OVMF.override {
          httpSupport = true;
          tlsSupport = true;
        };
      in
      {
        packages.default = pkgs.stdenvNoCC.mkDerivation {
          name = "miskefi";
          src = ./.;
          buildInputs = [ pkgs.zig_0_11 ];
          buildPhase = ''
            zig build -p $out --global-cache-dir .cache \
              -Doptimize=ReleaseFast
          '';
        };

        apps.default = {
          type = "app";
          program = toString (pkgs.writeShellScript "miskefi" ''
            export PATH=${lib.makeBinPath [ pkgs.qemu_kvm ]}:$PATH
            exec zig build qemu -Dbios=${ovmf.firmware}
          '');
        };

        formatter = pkgs.nixpkgs-fmt;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ zig_0_11 qemu_kvm ];
          shellHook = ''
            echo 'Run: `zig build qemu -Dbios=${ovmf.firmware}`'
          '';
        };
      });
}
