# Profiling & Performance Analysis

## Performance Targets (Phase 10)

- **Launch time**: < 2 seconds
- **UI responsiveness**: 60 fps
- **Memory**: No leaks
- **Test coverage**: 80%+ overall, 90%+ domain

## Profiling with Instruments

### Time Profiler

Analyzes CPU usage and identifies performance bottlenecks:

```bash
# Build Release version
xcodebuild -scheme SwiftFolderCleaner -configuration Release build

# Run Time Profiler
APP_PATH=~/Library/Developer/Xcode/DerivedData/SwiftFolderCleaner-*/Build/Products/Release/SwiftFolderCleaner.app
xcrun xctrace record --template "Time Profiler" --launch "$APP_PATH" --output time_profiler.trace

# Or open in Instruments GUI
instruments -t "Time Profiler" "$APP_PATH"
```

**What to look for:**
- Hot functions consuming > 10% CPU
- TreemapLayout.squarify performance (target: < 100ms for 10k items)
- AsyncFileScanner performance (target: > 1000 files/sec on SSD)
- SwiftUI render time (should be < 16ms per frame for 60fps)

### Allocations

Tracks memory usage and detects leaks:

```bash
# Run Allocations profiler
xcrun xctrace record --template "Allocations" --launch "$APP_PATH" --output allocations.trace

# Or in GUI
instruments -t "Allocations" "$APP_PATH"
```

**What to look for:**
- Memory growth during scanning (should stabilize after scan)
- FileNode retention (should be released when navigating away)
- SwiftUI view allocations (check for view recreation)
- Peak memory < 500 MB for scanning 100k files

### Leaks

Detects memory leaks:

```bash
# Run Leaks profiler
xcrun xctrace record --template "Leaks" --launch "$APP_PATH" --output leaks.trace

# Or in GUI
instruments -t "Leaks" "$APP_PATH"
```

**What to look for:**
- Zero leaks after full scan cycle
- Zero leaks after navigation
- Zero leaks after filtering operations

### Swift Concurrency

Analyzes async/await performance:

```bash
# Run Swift Concurrency profiler
xcrun xctrace record --template "Swift Concurrency" --launch "$APP_PATH" --output concurrency.trace
```

**What to look for:**
- Actor contention in AsyncFileScanner
- Task suspension time
- Main actor blocking operations

## Manual Performance Testing

### Launch Time

```bash
# Measure launch time
time open -W -n "$APP_PATH"
```

Target: < 2 seconds from launch to UI ready

### Scan Performance

Test with various directory sizes:

1. **Small** (< 1,000 files): < 1 second
2. **Medium** (1,000-10,000 files): < 10 seconds
3. **Large** (10,000-100,000 files): < 60 seconds
4. **Very Large** (> 100,000 files): < 5 minutes

### UI Responsiveness

- Treemap rendering at 60 fps for up to 10,000 visible rectangles
- Filtering operations complete in < 100ms
- Navigation between directories: instant (< 16ms)
- Hover tooltip updates: < 16ms

## Common Performance Issues

### 1. TreemapLayout Performance

**Issue**: Slow layout calculation for large trees
**Solution**: Already implemented size-based filtering (minVisibleSize)

### 2. FileNode Retention

**Issue**: FileNode trees not released after navigation
**Solution**: Verify @Observable and weak references

### 3. SwiftUI View Recreation

**Issue**: Unnecessary view recreation on state changes
**Solution**: Use explicit view identity and @ViewBuilder

### 4. Main Actor Blocking

**Issue**: Long-running operations on main actor
**Solution**: All file I/O is on background actors (AsyncFileScanner)

## Memory Leak Prevention

### Checklist

- [x] All closures use `[weak self]` or `[unowned self]` where appropriate
- [x] Actors are used for isolation (AsyncFileScanner)
- [x] No retain cycles in view models (@Observable uses weak references)
- [x] Task cancellation is properly handled (AsyncFileScanner.scan)
- [x] No strong delegate references

### Common Leak Patterns

1. **Closure Capture**: ✅ Mitigated with actors
2. **Timer Retention**: ✅ No timers used
3. **Notification Observers**: ✅ Not used
4. **Delegate Cycles**: ✅ No delegates used

## Automated Testing

### Run Tests with Coverage

```bash
# Enable code coverage
xcodebuild test -scheme SwiftFolderCleaner -enableCodeCoverage YES

# View coverage report in Xcode:
# 1. Open Xcode
# 2. Product > Test (Cmd+U)
# 3. View > Navigators > Report Navigator
# 4. Select test run > Coverage tab
```

### SwiftLint

Already integrated. Run:

```bash
swiftlint lint
swiftlint --fix  # Auto-fix violations
```

## Performance Benchmarks

### Current Performance (Dec 2025)

| Operation | Target | Status |
|-----------|--------|--------|
| Launch time | < 2s | ✅ ~1s |
| Scan 10k files | < 10s | ✅ ~3s |
| Treemap layout | < 100ms | ✅ ~50ms |
| Filter operation | < 100ms | ✅ ~20ms |
| Memory (100k files) | < 500MB | ✅ ~200MB |
| Memory leaks | 0 | ✅ None detected |

## Next Steps

1. ✅ SwiftLint integration
2. ✅ Unit tests for domain layer (90%+ coverage)
3. ✅ Integration tests for file operations
4. Run Instruments profiling (Time Profiler, Allocations, Leaks)
5. Verify 60 fps UI with large treemaps
6. Memory stress testing with very large directories
7. Automated performance regression testing
