---
description: Run all tests for the project
allowed-tools: Bash
argument-hint: [test-name]
---

```bash
# All tests
xcodebuild test -scheme FolderCleaner

# Specific test (if $ARGUMENTS provided)
xcodebuild test -scheme FolderCleaner -only-testing:$ARGUMENTS
```
