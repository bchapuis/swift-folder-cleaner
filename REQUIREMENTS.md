# SwiftFolderCleaner - Requirements

**Mission:** Analyze disk usage, identify waste, clean it up.
**Philosophy:** Clean, focused interface for disk space management.

## Functional Requirements

### Scanning
- Native folder picker (NSOpenPanel) via "Scan Folder" button
- Recursive traversal with real-time progress (file count, total size)
- Task cancellation with instant response
- Async/await with structured concurrency

### Visualization
- **Treemap**: Rectangles proportional to size, color by file type
- **File List**: Sortable table view showing files/folders with size, type, date
- **Breadcrumbs**: Navigate directory hierarchy
- **Legends**: File type color legend and size filter legend
- Click to select files/folders (single selection)
- Hover tooltip on treemap: name, size, percentage
- Human-readable sizes (1.5 GB, 342 MB)

### File Analysis
- **Filter by Size**: Min/max size sliders with real-time filtering
- **Filter by Type**: Toggle file types (code, documents, images, videos, archives, etc.)
- **Filter by Name**: Text search for filename filtering
- **Selection**: Click to select single file/folder

### File Operations
- **Show in Finder**: Reveal selected file/folder using NSWorkspace
- **Delete**: Move to Trash with confirmation dialog (via FileOperationsService)
- File operations integrated with macOS security model

### State Management
- Real-time UI updates with @Observable pattern
- Efficient file tree indexing for fast queries
- Immutable state objects for predictable behavior

## Non-Functional Requirements

### Performance
- Scan large directories efficiently via async/await
- UI responsive during scanning (@MainActor)
- Efficient file tree indexing for fast filtering
- Fast treemap layout algorithm (squarified)
- Responsive UI with immediate visual feedback

### Platform
- macOS 14 Sonoma minimum
- Swift 5.9+, Swift Concurrency (async/await, actors)
- Universal binary (ARM64 + x86_64)
- App Sandbox enabled
- SwiftUI with @Observable macro

### Accessibility
- VoiceOver support for main UI elements
- Keyboard navigation
- System color scheme (auto light/dark mode)
- Standard macOS controls

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

## Implemented Features

### Current Architecture
- **Domain Layer**: FileNode, FileType, ScanResult, ScanProgress, ScanError, FileTypeDetector, TreemapLayout
- **Data Layer**: AsyncFileScanner for async file I/O
- **UI Layer**: ContentView, ScanResultView, TreemapView, FileListView, BreadcrumbView
- **State Management**: ScanViewModel, ScanResultViewModel, TreemapViewModel, FilterState, SelectionState, NavigationState
- **File Tree Operations**: FileTreeIndex, FileTreeQuery, FileTreeNavigator, FileTreeFilter, IndexedFileTree
- **File Operations**: FileActions, FileOperationsService

### Not Implemented (Removed)
- Duplicate file detection (DuplicateFinder removed)
- Security-scoped bookmarks and recent folders (BookmarkManager removed)
- Undo support for file operations
- Multiple selection (Cmd+Click, Shift+Click)
- Batch delete operations
- Keyboard shortcuts
- Window state persistence
- Drag-drop folder onto window
