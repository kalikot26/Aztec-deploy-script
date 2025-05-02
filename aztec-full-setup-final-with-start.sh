#!/bin/bash
set -e

echo "🧼 Cleaning up previous setups..."
sudo rm -rf /opt/wasi-sdk ~/aztec-packages ~/.foundry ~/.nvm ~/.cargo

echo "🔧 Installing base system dependencies..."
sudo apt update
sudo apt install -y build-essential curl git jq zstd wget unzip cmake clang-16 snapd netcat-openbsd gnupg software-properties-common docker.io docker-compose

echo "📦 Installing yq v4 via Snap and linking it..."
sudo apt remove -y yq || true
sudo snap install yq
sudo ln -sf /snap/bin/yq /usr/bin/yq

echo "📦 Installing Node.js v20.17.0 via NVM..."
if ! command -v nvm >/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
fi
nvm install 20.17.0
nvm use 20.17.0
nvm alias default 20.17.0

echo "📦 Installing Aztec CLI..."
npm install -g @aztec/cli

echo "📦 Installing Yarn v4.5.2 via Corepack..."
corepack enable
corepack prepare yarn@4.5.2 --activate

echo "📦 Installing Rust via rustup (1.85.0)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.85.0
source "$HOME/.cargo/env"

echo "📦 Installing WASI SDK 22..."
curl -s -L https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-22/wasi-sdk-22.0-linux.tar.gz | tar zxf -
sudo mv wasi-sdk-22.0 /opt/wasi-sdk

echo "📦 Installing Foundry..."
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
echo 'export PATH="$HOME/.foundry/bin:$PATH"' >> ~/.bashrc

echo "⚠️ Installing required nightly Foundry version..."
if ! foundryup -i nightly-256cc50331d8a00b86c8e1f18ca092a66e220da5; then
    echo "❌ Failed to install specific nightly. Falling back to latest..."
    foundryup
fi

echo "📦 Installing global npm tools (corepack, solhint)..."
npm install -g corepack solhint

echo "🚀 Cloning Aztec monorepo..."
cd ~
git clone --recursive https://github.com/AztecProtocol/aztec-packages.git
cd aztec-packages

echo "⚙️ Running Aztec bootstrap..."
./bootstrap.sh full

echo "📦 Installing Yarn packages..."
cd yarn-project
yarn install

echo "🎉 Setup complete! Starting Aztec dev environment..."
yarn dev
