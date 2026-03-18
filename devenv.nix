{ pkgs, lib, config, ... }:

let
  wasmTarget = "wasm32-wasip1";
  pluginName = "zellij-pane-tracker";
  pluginDir = "$HOME/.config/zellij/plugins";
in
{
  # Rust toolchain with WASM target support
  languages.rust = {
    enable = true;
    channel = "stable";
    targets = [ wasmTarget ];
  };

  # Additional packages needed for development
  packages = [
    pkgs.jq
    pkgs.bun
    pkgs.zellij
  ];

  # Build script - compiles the plugin to WASM
  scripts.build.exec = ''
    echo "Building ${pluginName} plugin..."
    cargo build --release --target ${wasmTarget}
    echo "Build complete: target/${wasmTarget}/release/${pluginName}.wasm"
  '';

  # Install script - builds and copies to Zellij plugins directory
  scripts.install.exec = ''
    build
    mkdir -p "${pluginDir}"
    cp "target/${wasmTarget}/release/${pluginName}.wasm" "${pluginDir}/"
    echo "Installed to ${pluginDir}/${pluginName}.wasm"
  '';

  # Lint the Rust code
  scripts.lint.exec = ''
    cargo clippy --target ${wasmTarget} -- -D warnings
    cargo fmt -- --check
  '';

  # Format the Rust code
  scripts.fmt.exec = ''
    cargo fmt
  '';

  # Install MCP server dependencies
  scripts.mcp-install.exec = ''
    cd "$DEVENV_ROOT/mcp-server"
    bun install
  '';

  # Run the MCP server (for local testing)
  scripts.mcp-run.exec = ''
    cd "$DEVENV_ROOT/mcp-server"
    bun run index.ts
  '';

  # Git hooks for code quality
  git-hooks.hooks = {
    rustfmt.enable = true;
    clippy.enable = true;
  };

  # Launch Zellij with the locally-built plugin loaded
  scripts.dev.exec = ''
    build
    local_wasm="$DEVENV_ROOT/target/${wasmTarget}/release/${pluginName}.wasm"
    echo "Starting Zellij with local plugin: $local_wasm"
    zellij --layout "$DEVENV_ROOT/dev-layout.kdl"
  '';

  enterShell = ''
    echo "zellij-pane-tracker development environment"
    echo ""
    echo "Available commands:"
    echo "  dev          - Build and launch Zellij with the local plugin"
    echo "  build        - Build the WASM plugin"
    echo "  install      - Build and copy to ${pluginDir}/"
    echo "  lint         - Run clippy and check formatting"
    echo "  fmt          - Format Rust code"
    echo "  mcp-install  - Install MCP server dependencies"
    echo "  mcp-run      - Run the MCP server"
    echo ""
  '';

  enterTest = ''
    build
  '';
}
