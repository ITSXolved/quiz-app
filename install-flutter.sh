#!/bin/bash

# Exit on error and print commands
set -ex

# Deployment Trigger: 2026-02-15 20:26

# Clone Flutter if it doesn't exist (Shallow clone to save space)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (shallow)..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
fi

# Add Flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Disable analytics to save resources
flutter config --no-analytics

# Precache web artifacts
echo "Downloading web artifacts..."
flutter precache --web

# Resolve dependencies
echo "Resolving dependencies..."
flutter pub get

# Build for web using HTML renderer (saves memory vs CanvasKit)
echo "Building for web..."
flutter build web --release --web-renderer html --no-tree-shake-icons

echo "Build complete!"
