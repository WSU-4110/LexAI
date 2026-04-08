#!/bin/bash
set -e

echo "Listing available simulators..."
xcrun simctl list devices

echo "Starting build and test..."

xcodebuild clean test \
  -project LexAI_iOS/LexAI_iOS.xcodeproj \
  -scheme LexAI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2'

echo "Build and tests completed successfully!"
