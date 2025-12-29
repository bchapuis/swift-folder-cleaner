import XCTest
@testable import FolderCleaner

final class FileTreeFilterTests: XCTestCase {
    var testTree: FileNode!

    override func setUp() {
        super.setUp()

        // Create a test tree
        let imageFile = FileNode(
            path: URL(fileURLWithPath: "/root/images/photo.jpg"),
            name: "photo.jpg",
            totalSize: 5_000_000,
            isDirectory: false,
            fileType: .image,
            children: []
        )

        let videoFile = FileNode(
            path: URL(fileURLWithPath: "/root/videos/movie.mp4"),
            name: "movie.mp4",
            totalSize: 100_000_000,
            isDirectory: false,
            fileType: .video,
            children: []
        )

        let codeFile = FileNode(
            path: URL(fileURLWithPath: "/root/code/main.swift"),
            name: "main.swift",
            totalSize: 10_000,
            isDirectory: false,
            fileType: .code,
            children: []
        )

        let smallFile = FileNode(
            path: URL(fileURLWithPath: "/root/small.txt"),
            name: "small.txt",
            totalSize: 100,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        testTree = FileNode(
            path: URL(fileURLWithPath: "/root"),
            name: "root",
            totalSize: 105_010_100,
            isDirectory: true,
            fileType: .other,
            children: [imageFile, videoFile, codeFile, smallFile]
        )
    }

    func testNoFiltersApplied() {
        let filter = FileTreeFilter()
        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, testTree.children.count)
        XCTAssertEqual(filtered.totalSize, testTree.totalSize)
    }

    func testFileTypeFilter() {
        var filter = FileTreeFilter()
        filter.enabledFileTypes = [.image]

        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertEqual(filtered.children[0].name, "photo.jpg")
        XCTAssertEqual(filtered.children[0].fileType, .image)
    }

    func testMultipleFileTypesFilter() {
        var filter = FileTreeFilter()
        filter.enabledFileTypes = [.image, .video]

        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, 2)
        let types = Set(filtered.children.map { $0.fileType })
        XCTAssertTrue(types.contains(.image))
        XCTAssertTrue(types.contains(.video))
    }

    func testSizeFilter() {
        var filter = FileTreeFilter()
        filter.minSize = 1_000_000 // 1 MB

        let filtered = filter.apply(to: testTree)

        // Should only include files >= 1 MB (photo.jpg and movie.mp4)
        XCTAssertEqual(filtered.children.count, 2)
        for child in filtered.children {
            XCTAssertGreaterThanOrEqual(child.totalSize, 1_000_000)
        }
    }

    func testMaxSizeFilter() {
        var filter = FileTreeFilter()
        filter.maxSize = 50_000_000 // 50 MB

        let filtered = filter.apply(to: testTree)

        // Should exclude movie.mp4 (100 MB)
        XCTAssertEqual(filtered.children.count, 3)
        for child in filtered.children {
            XCTAssertLessThanOrEqual(child.totalSize, 50_000_000)
        }
    }

    func testSizeRangeFilter() {
        var filter = FileTreeFilter()
        filter.minSize = 1_000
        filter.maxSize = 10_000_000

        let filtered = filter.apply(to: testTree)

        // Should include main.swift (10,000) and photo.jpg (5,000,000)
        XCTAssertEqual(filtered.children.count, 2)
        for child in filtered.children {
            XCTAssertGreaterThanOrEqual(child.totalSize, 1_000)
            XCTAssertLessThanOrEqual(child.totalSize, 10_000_000)
        }
    }

    func testCombinedFilters() {
        var filter = FileTreeFilter()
        filter.enabledFileTypes = [.image, .video]
        filter.minSize = 10_000_000 // 10 MB

        let filtered = filter.apply(to: testTree)

        // Should only include movie.mp4 (100 MB, video)
        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertEqual(filtered.children[0].name, "movie.mp4")
    }

    func testFilenameFilter() {
        var filter = FileTreeFilter()
        filter.filenamePattern = "*.swift"

        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertEqual(filtered.children[0].name, "main.swift")
    }

    func testFilenameFilterPartialMatch() {
        var filter = FileTreeFilter()
        filter.filenamePattern = "*main*"

        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertTrue(filtered.children[0].name.contains("main"))
    }

    func testFilenameFilterCaseInsensitive() {
        var filter = FileTreeFilter()
        filter.filenamePattern = "*SWIFT*"

        let filtered = filter.apply(to: testTree)

        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertEqual(filtered.children[0].name, "main.swift")
    }

    func testEmptyTree() {
        let emptyTree = FileNode(
            path: URL(fileURLWithPath: "/empty"),
            name: "empty",
            totalSize: 0,
            isDirectory: true,
            fileType: .other,
            children: []
        )

        let filter = FileTreeFilter()
        let filtered = filter.apply(to: emptyTree)

        XCTAssertEqual(filtered.children.count, 0)
        XCTAssertEqual(filtered.totalSize, 0)
    }

    func testFilterPreservesDirectoryStructure() {
        let nestedFile = FileNode(
            path: URL(fileURLWithPath: "/root/subdir/nested.swift"),
            name: "nested.swift",
            totalSize: 5000,
            isDirectory: false,
            fileType: .code,
            children: []
        )

        let subdir = FileNode(
            path: URL(fileURLWithPath: "/root/subdir"),
            name: "subdir",
            totalSize: 5000,
            isDirectory: true,
            fileType: .other,
            children: [nestedFile]
        )

        let tree = FileNode(
            path: URL(fileURLWithPath: "/root"),
            name: "root",
            totalSize: 5000,
            isDirectory: true,
            fileType: .other,
            children: [subdir]
        )

        var filter = FileTreeFilter()
        filter.enabledFileTypes = [.code]

        let filtered = filter.apply(to: tree)

        XCTAssertEqual(filtered.children.count, 1)
        XCTAssertTrue(filtered.children[0].isDirectory)
        XCTAssertEqual(filtered.children[0].children.count, 1)
        XCTAssertEqual(filtered.children[0].children[0].name, "nested.swift")
    }
}
