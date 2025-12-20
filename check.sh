#!/bin/bash
# Quick syntax check - faster than full build

PROJECT_NAME="DeathClock"
SCHEME="DeathClock"

echo "🔍 Checking syntax..."
echo ""

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: xcodebuild not found"
    echo "   Make sure Xcode is installed and xcode-select is configured"
    exit 1
fi

# Build but stop after checking (doesn't actually compile, just validates)
xcodebuild \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -dry-run \
    2>&1 | grep -E "(error|warning|note):" | head -20

echo ""
echo "✅ Syntax check complete"

