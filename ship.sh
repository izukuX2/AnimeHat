#!/bin/bash

# Wrapper for tools/ship.dart
# Passes all arguments directly to the Dart tool

echo "🚀 Launching AnimeHat Ship Tool v2..."
dart tools/ship.dart "$@"
