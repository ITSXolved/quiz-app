#!/bin/bash

# Exit on error
set -e

# Clone Flutter if it doesn't exist
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable flutter
fi

# Add Flutter to path
export PATH="$PATH:`pwd`/flutter/bin"

# Precache web artifacts
echo "Downloading web artifacts..."
flutter precache --web

# Resolve dependencies
echo "Resolving dependencies..."
flutter pub get

# Build for web
echo "Building for web..."
flutter build web --release --no-tree-shake-icons

echo "Build complete!"
