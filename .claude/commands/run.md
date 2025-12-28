---
description: Clean, build, and run the Disk Analyzer application
allowed-tools: Bash
---

Clean, build, and run the DiskAnalyzer macOS application.

You should:
1. Clean the project and remove derived data
2. Build the application using xcodebuild
3. Launch the app using the open command
4. Confirm the app has been launched

```bash
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData/*DiskAnalyzer* && xcodebuild -scheme DiskAnalyzer -configuration Debug build && open ~/Library/Developer/Xcode/DerivedData/DiskAnalyzer-*/Build/Products/Debug/DiskAnalyzer.app
```
