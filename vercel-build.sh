#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.44.0"

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION" _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"

flutter config --no-analytics
flutter pub get
flutter build web --release
