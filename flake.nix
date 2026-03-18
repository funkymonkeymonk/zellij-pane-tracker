{
  description = "Zellij pane tracker plugin - exports pane metadata for AI assistants";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, crane, rust-overlay, flake-utils, devenv, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };

        wasmTarget = "wasm32-wasip1";

        # Rust toolchain with WASM target
        rustToolchain = pkgs.rust-bin.stable.latest.default.override {
          targets = [ wasmTarget ];
        };

        # Crane configured with our custom toolchain
        craneLib = (crane.mkLib pkgs).overrideToolchain (_: rustToolchain);

        # Source filtering - only include Rust-relevant files
        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = path: type:
            (craneLib.filterCargoSources path type)
            || (builtins.baseNameOf path == "config.toml" && builtins.match ".*\\.cargo.*" path != null);
        };

        commonArgs = {
          inherit src;
          strictDeps = true;
          cargoExtraArgs = "--target ${wasmTarget}";
          # WASM targets can't run tests natively
          doCheck = false;
        };

        # Build dependencies separately for caching
        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        # The WASM plugin
        zellij-pane-tracker = craneLib.buildPackage (commonArgs // {
          inherit cargoArtifacts;

          # Let crane's default install handle placing the .wasm,
          # then reorganize into the zellij plugins directory structure
          postInstall = ''
            mkdir -p $out/share/zellij/plugins
            mv $out/bin/*.wasm $out/share/zellij/plugins/
            rm -rf $out/bin
          '';
        });

      in
      {
        checks = {
          inherit zellij-pane-tracker;

          fmt = craneLib.cargoFmt { inherit src; };
        };

        packages = {
          default = zellij-pane-tracker;
          inherit zellij-pane-tracker;
        };

        # devenv shell for development
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [ ./devenv.nix ];
        };
      }
    );
}
