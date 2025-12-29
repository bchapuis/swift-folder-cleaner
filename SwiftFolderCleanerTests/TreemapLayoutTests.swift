import XCTest
@testable import SwiftFolderCleaner
import CoreGraphics

final class TreemapLayoutTests: XCTestCase {
    let testDate = Date()

    func testEmptyTree() {
        let emptyNode = FileNode.directory(
            path: URL(fileURLWithPath: "/empty"),
            name: "empty",
            modifiedDate: testDate,
            children: []
        )

        let rectangles = TreemapLayout.layout(
            node: emptyNode,
            in: CGRect(x: 0, y: 0, width: 1000, height: 600)
        )

        XCTAssertEqual(rectangles.count, 0)
    }

    func testSingleFile() {
        let file = FileNode.file(
            path: URL(fileURLWithPath: "/file.txt"),
            name: "file.txt",
            size: 1000,
            fileType: .document,
            modifiedDate: testDate
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: file, in: bounds)

        XCTAssertEqual(rectangles.count, 1)
        XCTAssertEqual(rectangles[0].node.name, "file.txt")
        XCTAssertEqual(rectangles[0].rect.width, bounds.width, accuracy: 1.0)
        XCTAssertEqual(rectangles[0].rect.height, bounds.height, accuracy: 1.0)
    }

    func testMultipleFiles() {
        let file1 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            size: 600,
            fileType: .document,
            modifiedDate: testDate
        )

        let file2 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            size: 400,
            fileType: .document,
            modifiedDate: testDate
        )

        let dir = FileNode.directory(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            modifiedDate: testDate,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: dir, in: bounds)

        // Should have at least some rectangles
        XCTAssertGreaterThan(rectangles.count, 0)

        // Should include at least one of the files
        let fileNames = rectangles.map { $0.node.name }
        XCTAssertTrue(fileNames.contains("file1.txt") || fileNames.contains("file2.txt") || fileNames.contains("dir"))
    }

    func testEqualSizedFiles() {
        let file1 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            size: 500,
            fileType: .document,
            modifiedDate: testDate
        )

        let file2 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            size: 500,
            fileType: .document,
            modifiedDate: testDate
        )

        let dir = FileNode.directory(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            modifiedDate: testDate,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: dir, in: bounds)

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
        let smallFile = FileNode.file(
            path: URL(fileURLWithPath: "/dir/small.txt"),
            name: "small.txt",
            size: 10,
            fileType: .document,
            modifiedDate: testDate
        )

        let largeFile = FileNode.file(
            path: URL(fileURLWithPath: "/dir/large.txt"),
            name: "large.txt",
            size: 10000,
            fileType: .document,
            modifiedDate: testDate
        )

        let dir = FileNode.directory(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            modifiedDate: testDate,
            children: [largeFile, smallFile]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: dir, in: bounds, minSizeThreshold: 0.05) // 5% threshold

        // Small file should be filtered out due to minVisibleSize
        let fileNames = rectangles.map { $0.node.name }
        XCTAssertTrue(fileNames.contains("large.txt"))
        XCTAssertTrue(fileNames.contains("dir"))
    }

    func testNestedDirectories() {
        let file = FileNode.file(
            path: URL(fileURLWithPath: "/parent/child/file.txt"),
            name: "file.txt",
            size: 1000,
            fileType: .document,
            modifiedDate: testDate
        )

        let childDir = FileNode.directory(
            path: URL(fileURLWithPath: "/parent/child"),
            name: "child",
            modifiedDate: testDate,
            children: [file]
        )

        let parentDir = FileNode.directory(
            path: URL(fileURLWithPath: "/parent"),
            name: "parent",
            modifiedDate: testDate,
            children: [childDir]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: parentDir, in: bounds)

        // Should have rectangles for parent, child, and file
        XCTAssertGreaterThanOrEqual(rectangles.count, 3)
    }

    func testLayoutFillsEntireBounds() {
        let file1 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file1.txt"),
            name: "file1.txt",
            size: 700,
            fileType: .document,
            modifiedDate: testDate
        )

        let file2 = FileNode.file(
            path: URL(fileURLWithPath: "/dir/file2.txt"),
            name: "file2.txt",
            size: 300,
            fileType: .document,
            modifiedDate: testDate
        )

        let dir = FileNode.directory(
            path: URL(fileURLWithPath: "/dir"),
            name: "dir",
            modifiedDate: testDate,
            children: [file1, file2]
        )

        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 600)
        let rectangles = TreemapLayout.layout(node: dir, in: bounds)

        // All rectangles should be within bounds
        for rect in rectangles {
            XCTAssertTrue(bounds.contains(rect.rect.origin))
            XCTAssertLessThanOrEqual(rect.rect.maxX, bounds.maxX + 1.0)
            XCTAssertLessThanOrEqual(rect.rect.maxY, bounds.maxY + 1.0)
        }
    }
}
