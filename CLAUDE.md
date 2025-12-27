# CLAUDE.md

Quick reference for Claude Code.

## Commands

```bash
# Run
open DiskAnalyzer.xcodeproj  # Cmd+R in Xcode
xcodebuild -scheme DiskAnalyzer -configuration Debug

# Build
xcodebuild -scheme DiskAnalyzer -configuration Release build

# Test
xcodebuild test -scheme DiskAnalyzer
swift test

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*DiskAnalyzer*

# Archive & Export
xcodebuild archive -scheme DiskAnalyzer -archivePath ./build/DiskAnalyzer.xcarchive
xcodebuild -exportArchive -archivePath ./build/DiskAnalyzer.xcarchive -exportPath ./build/Release -exportOptionsPlist ExportOptions.plist

# Code Sign & Notarize
codesign --deep --force --sign "Developer ID Application" ./build/Release/DiskAnalyzer.app
xcrun notarytool submit ./build/DiskAnalyzer.dmg --keychain-profile "AC_PASSWORD" --wait
xcrun stapler staple ./build/DiskAnalyzer.dmg

# Lint
swiftlint lint
swiftlint --fix

# DocC
xcodebuild docbuild -scheme DiskAnalyzer -destination 'platform=macOS'

# Profile
instruments -t "Time Profiler" ./build/Release/DiskAnalyzer.app
instruments -t "Allocations" ./build/Release/DiskAnalyzer.app
```

## Tech Stack

- Swift 5.9+, SwiftUI, macOS 13+
- Xcode 15+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64 + x86_64)

## Structure

```
DiskAnalyzer/
├── DiskAnalyzer.xcodeproj
├── DiskAnalyzer/
│   ├── DiskAnalyzerApp.swift  # @main
│   ├── Info.plist
│   ├── DiskAnalyzer.entitlements
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
