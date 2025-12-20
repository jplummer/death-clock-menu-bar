#!/bin/bash
# Build script for DeathClock - can be run from Cursor's terminal

set -e

PROJECT_NAME="DeathClock"
SCHEME="DeathClock"
CONFIGURATION="Debug"

echo "🔨 Building $PROJECT_NAME..."
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found"
    echo "   Make sure Xcode is installed and xcode-select is configured:"
    echo "   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

# Build using xcodebuild and capture exit code
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    build \
    2>&1 | tee build.log

BUILD_EXIT_CODE=${PIPESTATUS[0]}

# Check if build succeeded
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ Build succeeded!"
    echo ""
    echo "To run the app:"
    echo "  open ~/Library/Developer/Xcode/DerivedData/DeathClock-*/Build/Products/Debug/$PROJECT_NAME.app"
else
    echo ""
    echo "❌ Build failed (exit code: $BUILD_EXIT_CODE)"
    echo "   Check build.log for details, or run:"
    echo "   tail -50 build.log"
    exit 1
fi

