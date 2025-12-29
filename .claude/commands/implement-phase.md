---
description: Implement a specific phase from PLAN.md
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
argument-hint: <phase-number>
---

Phase: $1

1. Read Phase $1 in PLAN.md
2. Reference REQUIREMENTS.md, DESIGN.md
3. Implement tasks
4. Write tests (XCTest)
5. Run: `xcodebuild test -scheme FolderCleaner`
6. Verify checkpoint
7. Update PLAN.md checkboxes
8. Build: `xcodebuild build -scheme FolderCleaner`

Use subagents: swift-architect, test-engineer, performance-optimizer, ui-polish
