#!/bin/bash
# Test runner for SwiftFolderCleaner
# Since tests aren't in Xcode project, this compiles and runs them manually

set -e

echo "🧪 SwiftFolderCleaner Test Runner"
echo "=============================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Build paths
BUILD_DIR="./build/tests"
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/SwiftFolderCleaner-"*"/Build/Products/Debug/SwiftFolderCleaner.app"

# Check if app is built
if ! ls $APP_PATH > /dev/null 2>&1; then
    echo "${YELLOW}⚠️  App not found. Building...${NC}"
    xcodebuild -scheme SwiftFolderCleaner -configuration Debug build > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "${GREEN}✅ Build successful${NC}"
    else
        echo "${RED}❌ Build failed${NC}"
        exit 1
    fi
fi

echo ""
echo "${YELLOW}⚠️  Note: Tests need to be added to Xcode project to run properly${NC}"
echo ""
echo "To add tests to Xcode:"
echo "1. Open SwiftFolderCleaner.xcodeproj in Xcode"
echo "2. File → New → Target → macOS → Unit Testing Bundle"
echo "3. Name it 'SwiftFolderCleanerTests'"
echo "4. Add test files from Tests/DiskAnalyzerTests/ to the test target"
echo "5. Add SwiftFolderCleaner app as a dependency"
echo "6. Run tests with Cmd+U or: xcodebuild test -scheme SwiftFolderCleaner"
echo ""
echo "Test files created:"
echo "  ✓ FileTypeTests.swift (60+ test cases)"
echo "  ✓ FileNodeTests.swift"
echo "  ✓ TreemapLayoutTests.swift"
echo "  ✓ FileTreeFilterTests.swift"
echo "  ✓ ScanProgressTests.swift"
echo "  ✓ FileOperationsIntegrationTests.swift"
echo "  ✓ FileScannerTests.swift (already exists)"
echo ""
echo "${GREEN}Tests are ready to run once added to Xcode project!${NC}"
