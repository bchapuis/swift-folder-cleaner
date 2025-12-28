---
name: xcode-swift-build
description: Auto-invoked for building, testing, packaging Swift/Xcode projects.
allowed-tools: Bash, Read, Edit
---

## Commands

```bash
# Build
xcodebuild -scheme DirectoryCleaner build
xcodebuild -scheme DirectoryCleaner -configuration Release build

# Test
xcodebuild test -scheme DirectoryCleaner
xcodebuild test -only-testing:DirectoryCleanerTests/FileScannerTests

# Clean
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*DirectoryCleaner*

# Archive
xcodebuild archive -scheme DirectoryCleaner -archivePath ./build/DirectoryCleaner.xcarchive

# Universal Binary (ARM64 + x86_64)
xcodebuild -scheme DirectoryCleaner -configuration Release \
  -arch arm64 -arch x86_64 ONLY_ACTIVE_ARCH=NO build

# Verify architecture
lipo -info build/Release/DirectoryCleaner.app/Contents/MacOS/DirectoryCleaner
```

## Compiler Flags

```bash
# Enable strict concurrency (Swift 6 ready)
-strict-concurrency=complete
-enable-actor-data-race-checks
-warn-concurrency
```

## Entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

## Troubleshooting

```bash
# View entitlements
codesign -d --entitlements :- build/Release/DirectoryCleaner.app

# Verify signature
codesign --verify --verbose build/Release/DirectoryCleaner.app

# Clear caches
rm -rf ~/Library/Developer/Xcode/DerivedData
rm -rf ~/Library/Caches/org.swift.swiftpm
```
