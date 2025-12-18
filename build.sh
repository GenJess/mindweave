#!/bin/bash
set -e  # Exit on any error

echo "🚀 Starting Flutter Web Build..."

# Clone Flutter if not already present
if [ ! -d "/tmp/flutter" ]; then
  echo "📦 Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 /tmp/flutter
else
  echo "✓ Flutter SDK already exists"
fi

# Add Flutter to PATH
export PATH="$PATH:/tmp/flutter/bin"

# Verify Flutter is accessible
echo "🔍 Verifying Flutter installation..."
flutter --version

# Configure Flutter
echo "⚙️ Configuring Flutter..."
flutter config --no-analytics
flutter config --enable-web

# Precache web tools
echo "📥 Downloading web tools..."
flutter precache --web

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building for web..."
flutter build web --release --base-href /

echo "✅ Build complete!"
