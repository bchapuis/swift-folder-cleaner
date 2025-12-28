---
description: Run all tests for the project
allowed-tools: Bash
argument-hint: [test-name]
---

```bash
# All tests
xcodebuild test -scheme DirectoryCleaner

# Specific test (if $ARGUMENTS provided)
xcodebuild test -scheme DirectoryCleaner -only-testing:$ARGUMENTS
```
