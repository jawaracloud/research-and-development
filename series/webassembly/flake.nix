{
  description = "WebAssembly with Rust & Leptos — 100-lesson dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        # Pin Rust toolchain — same version as Dockerfile
        rustToolchain = pkgs.rust-bin.stable."1.85.0".default.override {
          extensions = [ "rust-analyzer" "clippy" "rustfmt" "llvm-tools-preview" ];
          targets    = [ "wasm32-unknown-unknown" ];
        };

        # Cargo tools built from source (locked versions match Dockerfile)
        cargoTools = pkgs.buildEnv {
          name = "wasm-cargo-tools";
          paths = [
            (pkgs.rustPlatform.buildRustPackage rec {
              pname = "wasm-pack";
              version = "0.13.1";
              src = pkgs.fetchCrate { inherit pname version;
                hash = "sha256-PLACEHOLDER_WASM_PACK"; };
              cargoHash = "sha256-PLACEHOLDER";
            })
          ];
        };

      in {
        devShells.default = pkgs.mkShell {
          name = "wasm-series";

          buildInputs = [
            # ── Rust toolchain ────────────────────────────────────────────
            rustToolchain

            # ── Wasm tools (packaged in nixpkgs) ─────────────────────────
            pkgs.wasm-pack
            pkgs.wasm-bindgen-cli
            pkgs.binaryen        # wasm-opt
            pkgs.wabt            # wat2wasm, wasm2wat

            # ── Cargo tools (from nixpkgs) ────────────────────────────────
            pkgs.cargo-watch
            pkgs.cargo-generate
            pkgs.cargo-expand
            pkgs.sqlx-cli

            # ── Node.js (Playwright, Tailwind, Playwright) ─────────────────
            pkgs.nodejs_22
            pkgs.nodePackages.npm

            # ── System deps ───────────────────────────────────────────────
            pkgs.pkg-config
            pkgs.openssl
            pkgs.libiconv

            # ── Utilities ─────────────────────────────────────────────────
            pkgs.jq
            pkgs.git
            pkgs.curl
            pkgs.wget
          ];

          # trunk and cargo-leptos are not yet in nixpkgs stable — install via cargo
          shellHook = ''
            echo ""
            echo "  🦀 WebAssembly + Rust + Leptos Dev Shell"
            echo "  ─────────────────────────────────────────"
            echo "  $(rustc --version)"
            echo "  wasm-pack $(wasm-pack --version 2>/dev/null || echo 'not found')"
            echo ""

            # Install trunk and cargo-leptos into ~/.cargo/bin if missing
            if ! command -v trunk &>/dev/null; then
              echo "  📦 Installing trunk..."
              cargo install trunk --version "0.21.4" --locked --quiet
            fi

            if ! command -v cargo-leptos &>/dev/null; then
              echo "  📦 Installing cargo-leptos..."
              cargo install cargo-leptos --version "0.2.34" --locked --quiet
            fi

            echo "  ✅ Environment ready! Run ./scripts/verify-env.sh to confirm."
            echo ""

            # Ensure wasm32 target is present
            rustup target add wasm32-unknown-unknown 2>/dev/null || true
          '';

          # Environment variables
          RUST_BACKTRACE = "1";
          RUST_LOG = "debug";
          DATABASE_URL = "sqlite:./dev.db";
        };
      }
    );
}
