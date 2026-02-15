#!/bin/bash

# Exit on error
set -e

# Clone Flutter SDK
if [ -d "flutter" ]; then
    cd flutter
    git pull
    cd ..
else
    git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Run Flutter doctor to download dependencies
flutter doctor -v

# Enable web support
flutter config --enable-web

# Build the web project
flutter build web --release
