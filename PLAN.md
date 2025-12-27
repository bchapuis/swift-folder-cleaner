# Implementation Plan

## Phase 1: Foundation & Domain

**Goal:** Core file scanning logic, no UI

- [ ] 1.1: Initialize Xcode project (Swift 5.9+, macOS 14+, universal binary)
- [ ] 1.2: Domain models: `FileNode`, `FileType`, `ScanResult`, `ScanProgress`, `ScanError` (all Sendable/Identifiable)
- [ ] 1.3: File type detection via pathExtension and UTType
- [ ] 1.4: Synchronous scanner: recursive traversal, size calculation, tree building
- [ ] 1.5: async/await conversion with Task cancellation and Actor isolation

**Checkpoint:** Scan test directory, verify correct sizes and tree structure

## Phase 2: Progress & State

**Goal:** Progress tracking and state management

- [ ] 2.1: `ScanState` enum, `ScanViewModel` (@Observable/@MainActor)
- [ ] 2.2: Actor for thread-safe progress, AsyncStream for updates, speed/ETA calculation
- [ ] 2.3: `ScanError` enum with LocalizedError, graceful error handling

**Checkpoint:** Scan 1000+ files with streaming progress and error recovery

## Phase 3: Basic UI

**Goal:** Main window layout, folder selection

- [ ] 3.1: Window: toolbar, content area, status bar (SwiftUI + Previews)
- [ ] 3.2: Welcome screen: button, drag-drop, quick access, ContentUnavailableView
- [ ] 3.3: NSOpenPanel + security-scoped bookmarks, UserDefaults for recent folders
- [ ] 3.4: Connect UI to ViewModel, display scan state with ProgressView

**Checkpoint:** Select folder, scan, see completion (bookmark persists across launches)

## Phase 4: File Browser & Details

**Goal:** Tree list display with details panel

- [ ] 4.1: OutlineGroup/List with name/size/type columns, SF Symbols, lazy loading
- [ ] 4.2: Selection handling (@State), ViewModel sync, Sendable selection
- [ ] 4.3: Details panel: path, size, %, date, count (ByteCountFormatter)
- [ ] 4.4: Human-readable size formatting (extension on Int64)

**Checkpoint:** Browse tree, select items, see details update

## Phase 5: Treemap Algorithm

**Goal:** Layout calculation

- [ ] 5.1: Choose squarified treemap algorithm
- [ ] 5.2: Pure layout function: FileNode + CGRect → [TreemapRectangle]
- [ ] 5.3: FileType → Color mapping (WCAG AA, light/dark mode)
- [ ] 5.4: Optimize for 10,000+ items, profile with Instruments (< 100ms target)

**Checkpoint:** Verify layout fills space with good aspect ratios

## Phase 6: Treemap Rendering

**Goal:** Draw treemap in UI

- [ ] 6.1: Canvas-based rendering, responsive to size changes
- [ ] 6.2: Tap/click selection, sync with file browser
- [ ] 6.3: Hover effects with cursor, display tooltip (name, size, %)
- [ ] 6.4: Color legend

**Checkpoint:** Interactive treemap at 60fps

## Phase 7: Navigation

**Goal:** Zoom and breadcrumbs

- [ ] 7.1: Double-click zoom into directory
- [ ] 7.2: Breadcrumb trail with clickable segments
- [ ] 7.3: Smooth zoom animations (300ms easing)
- [ ] 7.4: Keyboard navigation (arrows, Enter, Esc)

**Checkpoint:** Navigate deep directories via treemap and breadcrumbs

## Phase 8: File Operations

**Goal:** Filesystem actions

- [ ] 8.1: Show in Finder (NSWorkspace)
- [ ] 8.2: Move to trash (FileManager.trashItem) with confirmation
- [ ] 8.3: Batch selection and operations
- [ ] 8.4: Undo support for delete (NSUndoManager)

**Checkpoint:** Delete files, see them in trash, undo successfully

## Phase 9: Polish & UX

**Goal:** Refinements

- [ ] 9.1: Loading states (skeleton, spinners)
- [ ] 9.2: Empty states (SF Symbols, friendly messaging)
- [ ] 9.3: Error states with retry actions
- [ ] 9.4: Animations (200-300ms easing), respect Reduce Motion
- [ ] 9.5: Keyboard shortcuts with tooltips
- [ ] 9.6: Drag-drop folder onto window

**Checkpoint:** All states feel polished, animations smooth

## Phase 10: Accessibility

**Goal:** Full a11y support

- [ ] 10.1: VoiceOver labels and hints for all interactive elements
- [ ] 10.2: Keyboard navigation (FocusState) for entire UI
- [ ] 10.3: Dynamic Type support (@ScaledMetric)
- [ ] 10.4: High Contrast mode testing
- [ ] 10.5: Reduce Motion testing

**Checkpoint:** Navigate entire app via VoiceOver and keyboard only

## Phase 11: Performance & Testing

**Goal:** Optimize and validate

- [ ] 11.1: Profile with Instruments (Time Profiler, Allocations)
- [ ] 11.2: SwiftLint integration, fix warnings
- [ ] 11.3: Unit test coverage (domain 90%+, data 80%+)
- [ ] 11.4: Integration tests for file operations
- [ ] 11.5: UI tests (XCUITest) for critical flows
- [ ] 11.6: Memory leak detection (Instruments Leaks)

**Checkpoint:** < 2s launch, 60fps UI, no leaks, 80%+ coverage

## Phase 12: Distribution

**Goal:** Prepare for release

- [ ] 12.1: App icon and assets (1024px master)
- [ ] 12.2: Code signing (Developer ID), entitlements configuration
- [ ] 12.3: Hardened Runtime enabled
- [ ] 12.4: Notarization workflow (notarytool)
- [ ] 12.5: DMG or PKG installer creation
- [ ] 12.6: DocC documentation generation
- [ ] 12.7: Release notes

**Checkpoint:** Notarized, signed app installs and runs on clean Mac
