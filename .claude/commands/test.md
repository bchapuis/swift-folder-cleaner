---
description: Run all tests for the project
allowed-tools: Bash
argument-hint: [test-name]
---

```bash
# All tests
xcodebuild test -scheme SwiftFolderCleaner

# Specific test (if $ARGUMENTS provided)
xcodebuild test -scheme SwiftFolderCleaner -only-testing:$ARGUMENTS
```
