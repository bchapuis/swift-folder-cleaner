---
description: Clean, build, and run the Directory Cleaner application
allowed-tools: Bash
---

Clean, build, and run the DirectoryCleaner macOS application.

You should:
1. Clean the project and remove derived data
2. Build the application using xcodebuild
3. Launch the app using the open command
4. Confirm the app has been launched

```bash
xcodebuild clean && rm -rf ~/Library/Developer/Xcode/DerivedData/*DirectoryCleaner* && xcodebuild -scheme DirectoryCleaner -configuration Debug build && open ~/Library/Developer/Xcode/DerivedData/DirectoryCleaner-*/Build/Products/Debug/DirectoryCleaner.app
```
