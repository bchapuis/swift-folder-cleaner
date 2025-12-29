# CLAUDE.md

Quick reference for Claude Code.

## Commands

```bash
# Clean, Build & Run (use /run slash command)
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData/*FolderCleaner* && xcodebuild -scheme FolderCleaner -configuration Debug build && open ~/Library/Developer/Xcode/DerivedData/FolderCleaner-*/Build/Products/Debug/FolderCleaner.app

# Build (Release)
xcodebuild -scheme FolderCleaner -configuration Release build

# Test
xcodebuild test -scheme FolderCleaner
swift test

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*FolderCleaner*

# Archive & Export
xcodebuild archive -scheme FolderCleaner -archivePath ./build/FolderCleaner.xcarchive
xcodebuild -exportArchive -archivePath ./build/FolderCleaner.xcarchive -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# Code Sign & Notarize
codesign --deep --force --sign "Developer ID Application" ./build/Release/FolderCleaner.app
xcrun notarytool submit ./build/FolderCleaner.dmg --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple ./build/FolderCleaner.dmg

# Lint
swiftlint lint
swiftlint --fix

# DocC
xcodebuild docbuild -scheme FolderCleaner -destination 'platform=macOS'

# Profile
instruments -t "Time Profiler" ./build/Release/FolderCleaner.app
instruments -t "Allocations" ./build/Release/FolderCleaner.app
```

## Tech Stack

- Swift 5.9+, SwiftUI, macOS 13+
- Xcode 15+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64 + x86_64)

## Structure

```
FolderCleaner/
├── FolderCleaner.xcodeproj
├── FolderCleaner/
│   ├── FolderCleanerApp.swift  # @main
│   ├── Info.plist
│   ├── FolderCleaner.entitlements
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
