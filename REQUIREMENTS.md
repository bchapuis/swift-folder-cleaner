# Disk Analyzer - Requirements

## Functional Requirements

### Scanning
- Native folder picker (NSOpenPanel) with common locations, recent scans
- Recursive traversal with real-time progress (%, count, path, speed, ETA)
- Task cancellation with instant response
- Completion notification

### Visualization
- Treemap: rectangles proportional to size, color by type
- Interactive zoom with breadcrumb navigation
- Hover: name, size, percentage
- Legend for color scheme
- Human-readable sizes (1.5 GB, 342 MB)

### File Browser
- Collapsible tree view: name, size, type, date
- Sortable columns
- Type icons (SF Symbols)
- Bidirectional selection sync with treemap

### File Information
- Details panel: path, size, %, count, modified date
- Actions: Show in Finder, Move to Trash
- Top consumers list
- Confirmation dialogs for destructive operations

### Preferences
- Persist: window size, last location, panel visibility
- Keyboard shortcuts for all actions

## Non-Functional Requirements

### Performance
- Scan 100,000+ files efficiently via async/await
- UI responsive during scanning (@MainActor)
- Memory: lazy evaluation, streaming, proper ARC
- Launch under 2 seconds
- Treemap at 60fps

### Platform
- macOS 14 Sonoma (13 Ventura compatible)
- Swift 5.9+, Swift Concurrency
- Universal binary (ARM64 + x86_64)
- App Sandbox with security-scoped bookmarks

### Accessibility
- VoiceOver with descriptive labels
- Keyboard navigation (FocusState)
- Dynamic Type support
- WCAG AA contrast
- Reduce Motion support

### Design
- SF Pro typography with clear hierarchy
- System accent + semantic colors (blue/green/purple/orange)
- 8pt grid spacing
- SF Symbols icons
- Automatic light/dark mode

### Development
- Swift API Design Guidelines
- Swift Concurrency only (no GCD)
- DocC documentation
- Unit + integration tests
- SwiftUI previews
- Hardened Runtime + Notarization ready

## Out of Scope
- Duplicate detection, search, exports, custom themes
- Multiple scans, network optimization, Quick Look
- iOS/iPadOS, cloud/Spotlight integration
