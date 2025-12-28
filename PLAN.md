# Implementation Plan

**Simplified approach following Unix philosophy: Do one thing well.**

## Phase 1: Foundation & Domain

**Goal:** Core file scanning logic, no UI

- [x] 1.1: Initialize Xcode project (Swift 5.9+, macOS 14+, universal binary)
- [x] 1.2: Domain models: `FileNode`, `FileType`, `ScanResult`, `ScanProgress`, `ScanError`
- [x] 1.3: File type detection via pathExtension and UTType
- [x] 1.4: Synchronous scanner: recursive traversal, size calculation, tree building
- [x] 1.5: async/await conversion with Task cancellation and Actor isolation

**Checkpoint:** Scan test directory, verify correct sizes and tree structure

## Phase 2: Progress & State

**Goal:** Progress tracking and state management

- [x] 2.1: `ScanState` enum, `ScanViewModel` (@Observable/@MainActor)
- [x] 2.2: Actor for thread-safe progress, AsyncStream for updates, speed/ETA calculation
- [x] 2.3: `ScanError` enum with LocalizedError, graceful error handling

**Checkpoint:** Scan 1000+ files with streaming progress and error recovery

## Phase 3: Basic UI

**Goal:** Single-view app: scan → treemap → actions

- [x] 3.1: Window with scan button
- [x] 3.2: NSOpenPanel + security-scoped bookmarks, recent folders
- [x] 3.3: Display scan progress with ProgressView
- [ ] 3.4: Simplify to single ContentView (no separate Welcome/Scanning/Result views)

**Checkpoint:** Select folder, scan, see treemap

## Phase 4: Treemap Algorithm

**Goal:** Layout calculation (already complete)

- [x] 4.1: Squarified treemap algorithm
- [x] 4.2: Pure layout function: FileNode + CGRect → [TreemapRectangle]
- [x] 4.3: FileType → Color mapping (WCAG AA, light/dark mode)
- [x] 4.4: Optimized for 10,000+ items

**Checkpoint:** Verify layout fills space with good aspect ratios

## Phase 5: Treemap Rendering

**Goal:** Simple interactive treemap (no zoom, no breadcrumbs, no legend)

- [x] 5.1: Canvas-based rendering
- [x] 5.2: Click selection
- [x] 5.3: Hover tooltip (name, size, %)
- [ ] 5.4: Remove zoom functionality
- [ ] 5.5: Remove breadcrumb navigation
- [ ] 5.6: Remove color legend
- [ ] 5.7: Multiple selection (Cmd+Click, Shift+Click)

**Checkpoint:** Click to select, hover for info, treemap at 60fps

## Phase 6: File Analysis

**Goal:** Identify what to clean

- [ ] 6.1: Large file detection (>100MB, >1GB, >10GB filters)
- [ ] 6.2: Duplicate file finder (size + SHA-256 hash)
- [ ] 6.3: Top 10 largest files/folders
- [ ] 6.4: Filter UI in toolbar

**Checkpoint:** Find duplicates and large files instantly

## Phase 7: File Operations

**Goal:** Clean up disk space

- [ ] 7.1: Show in Finder (NSWorkspace)
- [ ] 7.2: Move to trash (FileManager.trashItem) with confirmation
- [ ] 7.3: Batch delete with size/count warnings
- [ ] 7.4: Undo support (NSUndoManager)
- [ ] 7.5: Delete button in toolbar, Cmd+Delete shortcut

**Checkpoint:** Delete files safely, see space reclaimed, undo works

## Phase 8: Polish & UX

**Goal:** Streamlined experience

- [ ] 8.1: Toolbar: [Scan] [Large Files ▾] [Duplicates] [Delete]
- [ ] 8.2: Status bar: "5 files selected (2.3 GB)"
- [ ] 8.3: Confirmation dialogs for >100MB or >10 files
- [ ] 8.4: Loading states (ProgressView)
- [ ] 8.5: Keyboard shortcuts with tooltips
- [ ] 8.6: Drag-drop folder onto window

**Checkpoint:** Clean, focused interface

## Phase 9: Accessibility

**Goal:** Full a11y support

- [ ] 9.1: VoiceOver labels for all interactive elements
- [ ] 9.2: Keyboard navigation (Tab, arrows, Space, Enter)
- [ ] 9.3: Dynamic Type support
- [ ] 9.4: High Contrast mode testing
- [ ] 9.5: Reduce Motion testing

**Checkpoint:** Navigate entire app via VoiceOver and keyboard

## Phase 10: Performance & Testing

**Goal:** Optimize and validate

- [ ] 10.1: Profile with Instruments (Time Profiler, Allocations)
- [ ] 10.2: SwiftLint integration
- [ ] 10.3: Unit test coverage (domain 90%+)
- [ ] 10.4: Integration tests for file operations
- [ ] 10.5: Memory leak detection

**Checkpoint:** < 2s launch, 60fps UI, no leaks, 80%+ coverage

## Phase 11: Distribution

**Goal:** Prepare for release

- [ ] 11.1: App icon and assets
- [ ] 11.2: Code signing (Developer ID)
- [ ] 11.3: Hardened Runtime
- [ ] 11.4: Notarization (notarytool)
- [ ] 11.5: DMG installer
- [ ] 11.6: DocC documentation
- [ ] 11.7: Release notes

**Checkpoint:** Notarized app installs and runs on clean Mac

## Removed Phases

**Eliminated to simplify:**
- ~~Phase 4: File Browser~~ (use Finder instead)
- ~~Phase 7: Navigation~~ (no zoom/breadcrumbs)
- ~~Multiple visualizations~~ (treemap only)
- ~~Details panel~~ (tooltip is enough)
- ~~Legend~~ (colors are obvious)
