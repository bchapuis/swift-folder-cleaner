# Disk Analyzer - Requirements

**Mission:** Analyze disk usage, identify waste, clean it up.
**Philosophy:** Do one thing well (Unix philosophy).

## Functional Requirements

### Scanning
- Native folder picker (NSOpenPanel) with recent scans
- Recursive traversal with real-time progress (%, count, speed, ETA)
- Task cancellation with instant response
- Completion notification

### Visualization
- Treemap: rectangles proportional to size, color by file type
- Click to select files/folders
- Hover tooltip: name, size, percentage
- Human-readable sizes (1.5 GB, 342 MB)
- No zoom, no breadcrumbs (use Finder for navigation)
- No legend (colors are self-explanatory)
- No separate file browser (use Finder)

### File Analysis
- **Find Large Files**: Filter by size (>100MB, >1GB, >10GB)
- **Find Duplicates**: Detect identical files by size + SHA-256 hash
- **Top 10 Largest**: Quick view of biggest space consumers
- **Selection**: Click to select, Cmd+Click for multiple, Shift+Click for range

### File Operations
- **Delete**: Move to Trash with confirmation dialog
- **Batch Delete**: Delete multiple selected items
- **Show in Finder**: Reveal selected file/folder
- **Undo Delete**: NSUndoManager support
- Confirmation for destructive operations (>100MB or >10 files)

### Preferences
- Persist: window size, last scan location
- Keyboard shortcuts for all actions

## Non-Functional Requirements

### Performance
- Scan 100,000+ files efficiently via async/await
- UI responsive during scanning (@MainActor)
- Duplicate detection streaming (don't load all in memory)
- Hash calculation on background threads
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
- System colors: file type colors (auto light/dark)
- 8pt grid spacing
- SF Symbols icons
- Minimal chrome, focus on treemap

### Development
- Swift API Design Guidelines
- Swift Concurrency only (no GCD)
- DocC documentation
- Unit + integration tests
- SwiftUI previews
- Hardened Runtime + Notarization ready

## Out of Scope
- Multiple simultaneous scans
- Search functionality (use Finder)
- Export reports/visualizations
- Custom themes
- Network drives optimization
- Quick Look integration
- iOS/iPadOS versions
- Cloud storage integration
- Spotlight integration
