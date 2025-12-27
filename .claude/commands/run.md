---
description: Run the Disk Analyzer application
allowed-tools: Bash
---

Build and run the DiskAnalyzer macOS application.

You should:
1. Build the application using xcodebuild
2. Launch the built app using the open command
3. Confirm the app has been launched

```bash
xcodebuild -scheme DiskAnalyzer -configuration Debug build 2>&1 | tail -20
open /Users/bchapuis/Library/Developer/Xcode/DerivedData/DiskAnalyzer-*/Build/Products/Debug/DiskAnalyzer.app
```

Alternative (open in Xcode):
```bash
open DiskAnalyzer.xcodeproj  # Then press Cmd+R in Xcode
```
