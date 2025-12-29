# CLAUDE.md

Quick reference for Claude Code.

## Commands

```bash
# Clean, Build & Run (use /run slash command)
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData/*SwiftFolderCleaner* && xcodebuild -scheme SwiftFolderCleaner -configuration Debug build && open ~/Library/Developer/Xcode/DerivedData/SwiftFolderCleaner-*/Build/Products/Debug/SwiftFolderCleaner.app

# Build (Release)
xcodebuild -scheme SwiftFolderCleaner -configuration Release build

# Test
xcodebuild test -scheme SwiftFolderCleaner
swift test

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*SwiftFolderCleaner*

# Archive & Export
xcodebuild archive -scheme SwiftFolderCleaner -archivePath ./build/SwiftFolderCleaner.xcarchive
xcodebuild -exportArchive -archivePath ./build/SwiftFolderCleaner.xcarchive -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# Code Sign & Notarize
codesign --deep --force --sign "Developer ID Application" ./build/Release/SwiftFolderCleaner.app
xcrun notarytool submit ./build/SwiftFolderCleaner.dmg --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple ./build/SwiftFolderCleaner.dmg

# Lint
swiftlint lint
swiftlint --fix

# DocC
xcodebuild docbuild -scheme SwiftFolderCleaner -destination 'platform=macOS'

# Profile
instruments -t "Time Profiler" ./build/Release/SwiftFolderCleaner.app
instruments -t "Allocations" ./build/Release/SwiftFolderCleaner.app
```

## Tech Stack

- Swift 5.9+, SwiftUI, macOS 13+
- Xcode 15+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64 + x86_64)

## Structure

```
SwiftFolderCleaner/
├── SwiftFolderCleaner.xcodeproj
├── SwiftFolderCleaner/
│   ├── SwiftFolderCleanerApp.swift  # @main
│   ├── Info.plist
│   ├── SwiftFolderCleaner.entitlements
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
