import XCTest
@testable import FolderCleaner
import CoreGraphics

final class TreemapLayoutTests: XCTestCase {
    func testEmptyTree() {
        let emptyNode = FileNode(
            path: URL(fileURLWithPath: "/empty"),
            name: "empty",
            totalSize: 0,
            isDirectory: true,
            fileType: .other,
            children: []
        )

        let rectangles = TreemapLayout.layout(
            root: emptyNode,
            bounds: CGRect(x: 0, y: 0, width: 1000, height: 600),
            minVisibleSize: 100
        )

        XCTAssertEqual(rectangles.count, 0)
    }

    func testSingleFile() {
        let file = FileNode(
            path: URL(fileURLWithPath: "/file.txt"),
            name: "file.txt",
            totalSize: 1000,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: file, bounds: bounds, minVisibleSize: 100)

        XCTAssertEqual(rectangles.count, 1)
        XCTAssertEqual(rectangles[0].node.name, "file.txt")
        XCTAssertEqual(rectangles[0].rect.width, bounds.width, accuracy: 1.0)
        XCTAssertEqual(rectangles[0].rect.height, bounds.height, accuracy: 1.0)
    }

    func testMultipleFiles() {
        let file1 = FileNode(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            totalSize: 600,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let file2 = FileNode(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            totalSize: 400,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let dir = FileNode(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            totalSize: 1000,
            isDirectory: true,
            fileType: .other,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: dir, bounds: bounds, minVisibleSize: 100)

        // Should have 3 rectangles: dir + file1 + file2
        XCTAssertEqual(rectangles.count, 3)

        // Verify total area is preserved
        let totalArea = bounds.width * bounds.height
        let rectsArea = rectangles.reduce(0.0) { $0 + ($1.rect.width * $1.rect.height) }
        XCTAssertEqual(rectsArea, totalArea, accuracy: 1.0)
    }

    func testEqualSizedFiles() {
        let file1 = FileNode(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            totalSize: 500,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let file2 = FileNode(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            totalSize: 500,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let dir = FileNode(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            totalSize: 1000,
            isDirectory: true,
            fileType: .other,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: dir, bounds: bounds, minVisibleSize: 100)

        XCTAssertEqual(rectangles.count, 3)

        // Find file rectangles
        let fileRects = rectangles.filter { !$0.node.isDirectory }
        XCTAssertEqual(fileRects.count, 2)

        // Equal sized files should have similar areas
        let area1 = fileRects[0].rect.width * fileRects[0].rect.height
        let area2 = fileRects[1].rect.width * fileRects[1].rect.height
        XCTAssertEqual(area1, area2, accuracy: 10.0)
    }

    func testMinVisibleSize() {
        let smallFile = FileNode(
            path: URL(fileURLWithPath: "/dir/small.txt"),
            name: "small.txt",
            totalSize: 10,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let largeFile = FileNode(
            path: URL(fileURLWithPath: "/dir/large.txt"),
            name: "large.txt",
            totalSize: 10000,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let dir = FileNode(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            totalSize: 10010,
            isDirectory: true,
            fileType: .other,
            children: [largeFile, smallFile]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: dir, bounds: bounds, minVisibleSize: 500)

        // Small file should be filtered out due to minVisibleSize
        let fileNames = rectangles.map { $0.node.name }
        XCTAssertTrue(fileNames.contains("large.txt"))
        XCTAssertTrue(fileNames.contains("dir"))
    }

    func testNestedDirectories() {
        let file = FileNode(
            path: URL(fileURLWithPath: "/parent/child/file.txt"),
            name: "file.txt",
            totalSize: 1000,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let childDir = FileNode(
            path: URL(fileURLWithPath: "/parent/child"),
            name: "child",
            totalSize: 1000,
            isDirectory: true,
            fileType: .other,
            children: [file]
        )

        let parentDir = FileNode(
            path: URL(fileURLWithPath: "/parent"),
            name: "parent",
            totalSize: 1000,
            isDirectory: true,
            fileType: .other,
            children: [childDir]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: parentDir, bounds: bounds, minVisibleSize: 100)

        // Should have rectangles for parent, child, and file
        XCTAssertGreaterThanOrEqual(rectangles.count, 3)
    }

    func testLayoutFillsEntireBounds() {
        let file1 = FileNode(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            totalSize: 700,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let file2 = FileNode(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            totalSize: 300,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let dir = FileNode(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            totalSize: 1000,
            isDirectory: true,
            fileType: .other,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(root: dir, bounds: bounds, minVisibleSize: 100)

        // All rectangles should be within bounds
        for rect in rectangles {
            XCTAssertTrue(bounds.contains(rect.rect.origin))
            XCTAssertLessThanOrEqual(rect.rect.maxX, bounds.maxX + 1.0)
            XCTAssertLessThanOrEqual(rect.rect.maxY, bounds.maxY + 1.0)
        }
    }
}
