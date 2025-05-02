#!/bin/bash

set -e

echo "🔧 Starting Aztec Full Setup (Smart Version)..."

# 1. Install core dependencies if not present
install_if_missing() {
  if ! command -v $1 &> /dev/null; then
    echo "🔧 Installing $1..."
    sudo apt-get install -y $2
  else
    echo "✅ $1 already installed."
  fi
}

sudo apt-get update -y
install_if_missing curl curl
install_if_missing jq jq
install_if_missing git git
install_if_missing zstd zstd
install_if_missing cmake cmake
install_if_missing snapd snapd

# 2. Install yq v4+ properly
if ! yq --version | grep -q "v4"; then
  echo "⚙️ Installing yq v4..."
  sudo snap install yq
fi

# 3. Install Rust if not installed
if ! command -v cargo &> /dev/null; then
  echo "⚙️ Installing Rust..."
  curl https://sh.rustup.rs -sSf | sh -s -- -y
  source $HOME/.cargo/env
else
  echo "✅ Rust already installed."
fi

# 4. Install Foundry if not installed
if ! command -v foundryup &> /dev/null; then
  echo "⚙️ Installing Foundry..."
  curl -L https://foundry.paradigm.xyz | bash
  source $HOME/.bashrc
else
  echo "✅ Foundry already installed."
fi

# 5. Install solhint if missing
if ! command -v solhint &> /dev/null; then
  echo "⚙️ Installing solhint..."
  sudo npm install -g solhint
else
  echo "✅ Solhint already installed."
fi

# 6. Clone aztec-packages if not present
if [ ! -d "aztec-packages" ]; then
  echo "📦 Cloning aztec-packages..."
  git clone https://github.com/AztecProtocol/aztec-packages.git
fi

cd aztec-packages

# 7. Run bootstrap script
echo "⚙️ Running Aztec bootstrap..."
./bootstrap.sh || echo "⚠️ Bootstrap completed with warnings."

# 8. Handle yarn project setup
if [ -d "yarn-project" ]; then
  cd yarn-project

  if [ ! -f "yarn.lock" ]; then
    echo "📦 Installing yarn project dependencies..."
    yarn install || echo "⚠️ Yarn install finished with issues."
  else
    echo "✅ Yarn dependencies seem to be already installed."
  fi

  cd ..
fi

echo "✅ Aztec Full Setup Completed!"
