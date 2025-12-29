# Testing Setup Guide

## Current Status

✅ **Test files created** (7 files, 90+ test cases)
⚠️ **Not yet integrated** into Xcode project

## Test Files

Located in `Tests/DiskAnalyzerTests/`:

1. **FileScannerTests.swift** - Async file scanning
2. **FileTypeTests.swift** - File type detection (60+ cases)
3. **FileNodeTests.swift** - Domain model operations
4. **TreemapLayoutTests.swift** - Layout algorithm validation
5. **FileTreeFilterTests.swift** - Filtering logic
6. **ScanProgressTests.swift** - Progress tracking
7. **FileOperationsIntegrationTests.swift** - End-to-end testing

## How to Add Tests to Xcode

### Option 1: Create Test Target (Recommended)

1. **Open Xcode**
   ```bash
   open FolderCleaner.xcodeproj
   ```

2. **Create Test Target**
   - File → New → Target
   - macOS → Unit Testing Bundle
   - Product Name: `FolderCleanerTests`
   - Language: Swift
   - Click Finish

3. **Delete Default Test File**
   - Delete the auto-generated `FolderCleanerTests.swift` file

4. **Add Test Files**
   - Select all test files in `Tests/DiskAnalyzerTests/`
   - Drag them into the project navigator
   - In the dialog:
     - ✅ Check "Copy items if needed"
     - ✅ Check target: `FolderCleanerTests`
     - Click Add

5. **Configure Test Target**
   - Select FolderCleanerTests target
   - Build Phases → Target Dependencies
   - Click + and add `FolderCleaner`

6. **Update Scheme**
   - Product → Scheme → Edit Scheme (Cmd+<)
   - Select Test action
   - Click + under Test section
   - Add FolderCleanerTests

### Option 2: Swift Package Manager

Convert project to use SPM:

1. **Create Package.swift**
   ```swift
   // swift-tools-version: 5.9
   import PackageDescription

   let package = Package(
       name: "FolderCleaner",
       platforms: [.macOS(.v13)],
       products: [
           .executable(name: "FolderCleaner", targets: ["FolderCleaner"])
       ],
       targets: [
           .executableTarget(name: "FolderCleaner"),
           .testTarget(
               name: "FolderCleanerTests",
               dependencies: ["FolderCleaner"]
           )
       ]
   )
   ```

2. **Run Tests**
   ```bash
   swift test
   ```

## Running Tests

### After Xcode Integration

```bash
# Run all tests
xcodebuild test -scheme FolderCleaner

# Run specific test class
xcodebuild test -scheme FolderCleaner -only-testing:FolderCleanerTests/FileTypeTests

# Run with coverage
xcodebuild test -scheme FolderCleaner -enableCodeCoverage YES

# Run in Xcode
# Press Cmd+U
```

### View Test Results

1. **In Xcode**
   - View → Navigators → Test Navigator (Cmd+6)
   - View → Navigators → Report Navigator (Cmd+9)

2. **Coverage Report**
   - Product → Test (Cmd+U)
   - Report Navigator → Select test run → Coverage tab
   - Filter by module: FolderCleaner

3. **Terminal**
   ```bash
   xcodebuild test -scheme FolderCleaner 2>&1 | \
     grep -E "(Test Suite|Test Case|passed|failed)"
   ```

## Expected Test Results

When tests are integrated and run:

```
Test Suite 'All tests' started
Test Suite 'FolderCleanerTests.xctest' started

FileTypeTests
  ✓ testImageFileType
  ✓ testVideoFileType
  ✓ testAudioFileType
  ✓ testCodeFileType
  (... 60+ more tests)

FileNodeTests
  ✓ testFileNodeCreation
  ✓ testDirectoryNodeWithChildren
  (... more tests)

TreemapLayoutTests
  ✓ testEmptyTree
  ✓ testSingleFile
  (... more tests)

FileTreeFilterTests
  ✓ testNoFiltersApplied
  ✓ testFileTypeFilter
  (... more tests)

ScanProgressTests
  ✓ testInitialProgress
  ✓ testProgressWithFiles
  (... more tests)

FileOperationsIntegrationTests
  ✓ testMoveFileToTrash
  ✓ testScanFilterAndDelete
  (... more tests)

FileScannerTests
  ✓ testScanEmptyDirectory
  ✓ testScanDirectoryWithFiles
  (... more tests)

Test Suite 'FolderCleanerTests' passed
   Total: 90+ tests
   Passed: 90+
   Failed: 0
   Duration: ~5 seconds
```

## Troubleshooting

### Tests Not Found

**Problem**: "No tests found" or scheme not configured
**Solution**: Verify test target is added to scheme (Product → Scheme → Edit Scheme → Test)

### Import Errors

**Problem**: `@testable import FolderCleaner` fails
**Solution**:
- Verify FolderCleaner is added as a dependency in test target
- Check that app target is named "FolderCleaner"
- Clean build folder: Product → Clean Build Folder (Cmd+Shift+K)

### Linker Errors

**Problem**: Undefined symbols during test compilation
**Solution**:
- All source files must be in FolderCleaner target
- Test files must be in FolderCleanerTests target only
- Check Build Phases → Compile Sources

### Test Files Not Running

**Problem**: Test files exist but don't execute
**Solution**:
- Verify files are in test target membership
- Check that classes inherit from `XCTestCase`
- Ensure test methods start with `test`

## Code Coverage Goals

| Module | Target | Actual |
|--------|--------|--------|
| Domain layer | 90% | TBD* |
| Data layer | 80% | TBD* |
| UI layer | 60% | TBD* |
| Overall | 80% | TBD* |

*Run tests with coverage enabled to populate

## Continuous Testing

### Watch Mode (Xcode)

File → Workspace Settings → Build System → Enable "Show live issues"

### Pre-commit Hook

Create `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Running tests..."
xcodebuild test -scheme FolderCleaner -quiet
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

```bash
chmod +x .git/hooks/pre-commit
```

## Next Steps

1. ⚠️ **Add test target to Xcode** (see Option 1 above)
2. Run tests: `xcodebuild test -scheme FolderCleaner`
3. Verify all 90+ tests pass
4. Generate coverage report
5. Fix any failures
6. Celebrate! 🎉
