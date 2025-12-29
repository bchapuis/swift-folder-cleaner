# Implementation Plan - SwiftFolderCleaner

**Status:** Feature complete. Polishing for release.

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
- [x] 2.2: Real-time progress updates with file count and total size
- [x] 2.3: `ScanError` enum with LocalizedError, graceful error handling

**Checkpoint:** Scan large directories with streaming progress and error recovery

## Phase 3: Basic UI

**Goal:** Functional UI with scan and visualization

- [x] 3.1: ContentView with scan button and folder picker
- [x] 3.2: NSOpenPanel for folder selection
- [x] 3.3: Display scan progress with ProgressView
- [x] 3.4: ScanResultView showing treemap and file list

**Checkpoint:** Select folder, scan, see results

## Phase 4: Treemap Algorithm

**Goal:** Layout calculation (already complete)

- [x] 4.1: Squarified treemap algorithm
- [x] 4.2: Pure layout function: FileNode + CGRect → [TreemapRectangle]
- [x] 4.3: FileType → Color mapping (WCAG AA, light/dark mode)
- [x] 4.4: Optimized for 10,000+ items

**Checkpoint:** Verify layout fills space with good aspect ratios

## Phase 5: Treemap Rendering

**Goal:** Interactive treemap visualization

- [x] 5.1: Canvas-based rendering with TreemapView
- [x] 5.2: Click selection (single selection)
- [x] 5.3: Hover tooltip (name, size, %)
- [x] 5.4: Breadcrumb navigation (BreadcrumbView)
- [x] 5.5: File type color legend (FileTypeLegend)
- [x] 5.6: Size filter legend (SizeFilterLegend)
- [x] 5.7: File list view alongside treemap (FileListView)

**Checkpoint:** Interactive treemap with navigation and tooltips

## Phase 6: File Analysis & Filtering

**Goal:** Advanced filtering capabilities

- [x] 6.1: Size filtering with min/max sliders (FilterState)
- [x] 6.2: File type filtering with toggles (FileTreeFilter)
- [x] 6.3: Filename search filtering (FilenameFilterView)
- [x] 6.4: Real-time filtering with FileTreeIndex and FileTreeQuery
- [x] 6.5: Efficient file tree navigation (FileTreeNavigator)

**Checkpoint:** Filter files by size, type, and name with instant results

## Phase 7: File Operations

**Goal:** File management capabilities

- [x] 7.1: Show in Finder (NSWorkspace via FileActions)
- [x] 7.2: Move to trash with confirmation (FileOperationsService)
- [x] 7.3: FileActions with async operations

**Checkpoint:** Delete files safely and reveal in Finder

## Phase 8: Polish & UX

**Goal:** Streamlined experience

- [x] 8.1: Filter UI with size sliders and type toggles
- [x] 8.2: Selection feedback with visual highlights
- [x] 8.3: Confirmation dialogs for delete operations
- [x] 8.4: Loading states (ProgressView during scan)
- [x] 8.5: Dark mode support with FileType color variants (WCAG AA in both modes)

**Checkpoint:** Polished, intuitive interface with dark mode support

## Phase 9: Accessibility & Localization

**Goal:** Full a11y and i18n support

- [x] 9.1: VoiceOver labels for all interactive elements (required for App Store)
- [x] 9.2: String extraction with .xcstrings catalog (required for i18n)
- [x] 9.3: Locale-aware number/size formatters (e.g., "1,234.56 MB" vs "1 234,56 Mo")
- [x] 9.4: Keyboard navigation (Tab, arrows, Space, Enter)
- [x] 9.5: Translations for EN, DE, ES, FR, ZH-Hans, PT, JA, RU, KO, IT

**Checkpoint:** Navigate entire app via VoiceOver and keyboard, UI displays correctly in all target languages

## Phase 10: Performance & Testing

**Goal:** Optimize and validate

- [x] 10.1: Profile with Instruments (Time Profiler, Allocations)
- [x] 10.2: SwiftLint integration
- [x] 10.3: Unit test coverage (domain 90%+)
- [x] 10.4: Integration tests for file operations
- [x] 10.5: Memory leak detection

**Checkpoint:** < 2s launch, 60fps UI, no leaks, 80%+ coverage

**Deliverables:**
- .swiftlint.yml configuration with 0 violations
- 6 comprehensive test files (FileTypeTests, FileNodeTests, TreemapLayoutTests, FileTreeFilterTests, ScanProgressTests, FileOperationsIntegrationTests)
- PROFILING.md - Performance analysis guide and benchmarks
- MEMORY_LEAK_ANALYSIS.md - Memory leak analysis and recommendations

## Phase 11: App Store Distribution

**Goal:** Submit to Mac App Store

- [ ] 11.1: App icon and assets
- [ ] 11.2: App Sandbox entitlements review (stricter than Developer ID)
- [ ] 11.3: Code signing with "Apple Distribution" certificate
- [ ] 11.4: App Store Connect configuration (metadata, screenshots, categories)
- [ ] 11.5: Archive and validate build
- [ ] 11.6: Upload to App Store Connect
- [ ] 11.7: DocC documentation
- [ ] 11.8: App Review submission with release notes

**Checkpoint:** App uploaded to App Store Connect and submitted for review

## Features Removed from Codebase

**Code cleanup (2025-12-29):**
- ~~BookmarkManager~~ - Security-scoped bookmarks and recent folders (not implemented)
- ~~FileScanner~~ - Synchronous scanner (replaced by AsyncFileScanner)
- ~~DuplicateFinder~~ - Duplicate file detection (not implemented)
- ~~NavigationPath~~ - Custom navigation structure (unused)

## Current State Summary

**Core Features (Complete):**
- Async file scanning with real-time progress
- Interactive treemap visualization (squarified layout)
- File list view with sortable columns
- Breadcrumb navigation
- File type and size filtering
- Filename search
- Show in Finder and delete operations
- Efficient file tree indexing

**Remaining Polish:**
- Dark mode support with proper color variants (Phase 8.5)
- Accessibility & Localization (VoiceOver, i18n foundation, 10 languages)
- Performance optimization and testing
- Distribution (code signing, notarization, DMG)

**Out of Scope:**
- Duplicate file detection
- Multiple selection / batch operations
- Undo/redo
- Advanced keyboard shortcuts
- Window state persistence
- Drag-drop support
