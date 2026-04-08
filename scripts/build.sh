#!/bin/bash
set -e

echo "Listing available simulators..."
xcrun simctl list devices

echo "Starting build and test..."

xcodebuild clean test \
  -project LexAI_iOS/LexAI_iOS.xcodeproj \
  -scheme LexAI_iOS \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.5'

echo "Build and tests completed successfully!"
