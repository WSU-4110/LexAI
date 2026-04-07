#!/bin/bash
set -e

echo "Starting build and test..."

xcodebuild clean test \
  -project LexAI_iOS.xcodeproj \
  -scheme LexAI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 15'

echo "Build and tests completed successfully!"
