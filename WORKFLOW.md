# Cursor + Xcode Workflow Guide

This guide explains how to use Cursor and Xcode together efficiently.

## How I (Auto) Can See Errors

I can already see errors in Cursor! Here's how:

1. **Linter Integration**: I can use `read_lints` to see Xcode's diagnostics
   - Just ask me to "check for errors" or I'll check automatically after edits
   - This shows compilation errors, warnings, and Swift diagnostics

2. **Terminal Builds**: I can run build commands and see output
   - Use `./build.sh` to build and see all errors
   - Use `./check.sh` for a quick syntax check

## Recommended Workflow

### Option 1: Cursor Primary (Recommended)
**Use Cursor for editing, Xcode for running/debugging**

1. **Edit in Cursor** - Make all your code changes here
2. **I check errors** - I'll automatically check lints after edits, or you can ask
3. **Build from terminal** - Run `./build.sh` in Cursor's terminal to see full build output
4. **Run in Xcode** - Keep Xcode open in the background, use it to:
   - Run the app (⌘R)
   - Debug (set breakpoints, inspect variables)
   - See console output
   - Use Instruments for profiling

**Benefits:**
- ✅ Best of both worlds
- ✅ Cursor's AI assistance for coding
- ✅ Xcode's debugging and runtime tools
- ✅ No context switching for editing

### Option 2: Split Screen
**Both tools open side-by-side**

1. Open Cursor on left, Xcode on right
2. Edit in Cursor
3. Xcode auto-detects file changes (if you have "Automatically Refresh Views" enabled)
4. Build/Run in Xcode to see results immediately

### Option 3: Terminal-Driven
**Use terminal for everything**

1. Edit in Cursor
2. Build with `./build.sh` (I can run this for you)
3. Run with `open build/Debug/DeathClock.app`
4. Check logs in terminal

## Quick Commands

### From Cursor Terminal:
```bash
# Full build (see all errors)
./build.sh

# Quick syntax check
./check.sh

# Build and run
./build.sh && open build/Debug/DeathClock.app

# Clean build
xcodebuild clean -project DeathClock.xcodeproj -scheme DeathClock
```

### From Me (Auto):
- "Check for errors" - I'll read linter diagnostics
- "Build the project" - I'll run the build script
- "Show me the build errors" - I'll check lints and run build

## Tips

1. **Keep Xcode open** - Even if you're editing in Cursor, keep Xcode open for:
   - Running the app
   - Debugging
   - Console output
   - Interface Builder (if you add UI later)

2. **File watching** - Xcode automatically detects file changes, so edits in Cursor appear in Xcode

3. **Source Control** - Both tools can use git, but be careful not to have both open the same file for editing simultaneously

4. **Build settings** - Xcode's build settings are the source of truth. Terminal builds use the same settings.

## Troubleshooting

**"xcodebuild requires Xcode, but active developer directory is command line tools"**
- Your system is pointing to Command Line Tools instead of full Xcode
- Fix it with: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
- Or if Xcode is in a different location, find it first: `mdfind -name Xcode.app`

**"Xcode shows different errors than Cursor"**
- Xcode might have cached build state. Clean build: `xcodebuild clean`
- Make sure both are looking at the same files

**"Can't see console output"**
- Console output only appears when running in Xcode
- Or use `log stream` command in terminal to see system logs

**"Build fails in terminal but works in Xcode"**
- Check that you're using the same scheme and configuration
- Xcode might have derived data cached
- Make sure xcode-select is pointing to full Xcode (see first troubleshooting item)

**"Couldn't create workspace arena folder" or "Operation not permitted"**
- DerivedData folder has permission issues
- Run `./fix-permissions.sh` to fix it
- Or manually: `rm -rf ~/Library/Developer/Xcode/DerivedData/DeathClock-*`
- Xcode will recreate it with correct permissions on next build

## Best Practice

**Recommended setup:**
1. Primary editing: Cursor (with me helping)
2. Running/Debugging: Xcode (keep it open)
3. Build verification: Terminal scripts (I can run these)

This gives you:
- ✅ AI-powered coding assistance
- ✅ Full debugging capabilities  
- ✅ Fast iteration
- ✅ No context switching

