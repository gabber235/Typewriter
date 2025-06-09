#!/usr/bin/env bash
set -euo pipefail

# Install Flutter for Linux
FLUTTER_VERSION="${FLUTTER_VERSION:-3.33.0-0.2.pre-beta}"
ARCHIVE="flutter_linux_${FLUTTER_VERSION}.tar.xz"

mkdir -p ~/development
cd ~/development

sudo apt-get update -y && sudo apt-get upgrade -y
sudo apt-get install -y curl git unzip xz-utils zip libglu1-mesa

if [ ! -f "$ARCHIVE" ]; then
  wget "https://storage.googleapis.com/flutter_infra_release/releases/beta/linux/${ARCHIVE}"
fi

tar xf "$ARCHIVE"

sudo chmod 777 -R ~/development
git config --global --add safe.directory ~/development/flutter

export PATH="$PATH:$(pwd)/flutter/bin"
grep -qxF 'export PATH="$HOME/development/flutter/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.bashrc

echo "Flutter installed. Restart your shell or run 'source ~/.bashrc' to use it."
