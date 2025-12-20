#!/bin/bash
# Fix DerivedData permissions issue

echo "🔧 Fixing Xcode DerivedData permissions..."
echo ""

DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData"

if [ -d "$DERIVED_DATA_PATH" ]; then
    echo "Found DerivedData at: $DERIVED_DATA_PATH"
    echo ""
    echo "Option 1: Remove the problematic DerivedData folder (recommended)"
    echo "  rm -rf $DERIVED_DATA_PATH/DeathClock-*"
    echo ""
    echo "Option 2: Fix permissions on the folder"
    echo "  sudo chown -R $(whoami) $DERIVED_DATA_PATH"
    echo ""
    echo "Option 3: Let Xcode recreate it (safest)"
    echo "  Close Xcode, then:"
    echo "  rm -rf $DERIVED_DATA_PATH/DeathClock-*"
    echo "  Reopen Xcode and build"
    echo ""
    read -p "Would you like to remove the DeathClock DerivedData folder now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$DERIVED_DATA_PATH"/DeathClock-*
        echo "✅ Removed DeathClock DerivedData folders"
        echo "   Next build will recreate them with correct permissions"
    fi
else
    echo "DerivedData folder not found at: $DERIVED_DATA_PATH"
    echo "This is normal if you haven't built in Xcode yet"
fi

