# CLAUDE.md

Quick reference for Claude Code.

## Commands

```bash
# Clean, Build & Run (use /run slash command)
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData/*DirectoryCleaner* && xcodebuild -scheme DirectoryCleaner -configuration Debug build && open ~/Library/Developer/Xcode/DerivedData/DirectoryCleaner-*/Build/Products/Debug/DirectoryCleaner.app

# Build (Release)
xcodebuild -scheme DirectoryCleaner -configuration Release build

# Test
xcodebuild test -scheme DirectoryCleaner
swift test

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*DirectoryCleaner*

# Archive & Export
xcodebuild archive -scheme DirectoryCleaner -archivePath ./build/DirectoryCleaner.xcarchive
xcodebuild -exportArchive -archivePath ./build/DirectoryCleaner.xcarchive -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# Code Sign & Notarize
codesign --deep --force --sign "Developer ID Application" ./build/Release/DirectoryCleaner.app
xcrun notarytool submit ./build/DirectoryCleaner.dmg --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple ./build/DirectoryCleaner.dmg

# Lint
swiftlint lint
swiftlint --fix

# DocC
xcodebuild docbuild -scheme DirectoryCleaner -destination 'platform=macOS'

# Profile
instruments -t "Time Profiler" ./build/Release/DirectoryCleaner.app
instruments -t "Allocations" ./build/Release/DirectoryCleaner.app
```

## Tech Stack

- Swift 5.9+, SwiftUI, macOS 13+
- Xcode 15+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64 + x86_64)

## Structure

```
DirectoryCleaner/
├── DirectoryCleaner.xcodeproj
├── DirectoryCleaner/
│   ├── DirectoryCleanerApp.swift  # @main
│   ├── Info.plist
│   ├── DirectoryCleaner.entitlements
│   ├── Domain/                 # Models, use cases
│   ├── Data/                   # FileManager, I/O
│   └── UI/                     # SwiftUI views
└── Tests/
```

## Key Files

**Info.plist**: Bundle ID, permissions, minimum macOS version
**Entitlements**: App Sandbox, file access, Hardened Runtime
**ExportOptions.plist**: Distribution config (Developer ID)

## Xcode Shortcuts

- **Cmd+B**: Build | **Cmd+R**: Run | **Cmd+U**: Test
- **Cmd+Shift+K**: Clean | **Cmd+Shift+O**: Open Quickly
- **Cmd+I**: Profile | **Cmd+Option+P**: Resume Preview
