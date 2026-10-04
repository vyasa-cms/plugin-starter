#!/usr/bin/env bash
# Build the component and pack dist/<name>-<version>.vyplugin (signed with
# VYASA_SIGNING_KEY, which packing requires). Needs the vyasa binary on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."
cargo build --release --target wasm32-wasip2
mkdir -p dist/pack
cp manifest.toml dist/pack/
cp target/wasm32-wasip2/release/*.wasm dist/pack/plugin.wasm
name=$(sed -n 's/^name = "\(.*\)"/\1/p' manifest.toml)
version=$(sed -n 's/^version = "\(.*\)"/\1/p' manifest.toml)
vyasa plugin pack dist/pack --out "dist/$name-$version.vyplugin"
