import XCTest
@testable import SwiftFolderCleaner

final class FileNodeTests: XCTestCase {
    let testDate = Date()

    func testFileNodeCreation() {
        let fileNode = FileNode.file(
            path: URL(fileURLWithPath: "/test/file.txt"),
            name: "file.txt",
            size: 1024,
            fileType: .document,
            modifiedDate: testDate
        )

        XCTAssertEqual(fileNode.name, "file.txt")
        XCTAssertEqual(fileNode.totalSize, 1024)
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertEqual(fileNode.fileType, .document)
        XCTAssertEqual(fileNode.children.count, 0)
        XCTAssertEqual(fileNode.fileCount, 1)
    }

    func testDirectoryNodeWithChildren() {
        let child1 = FileNode.file(
            path: URL(fileURLWithPath: "/test/dir/file1.txt"),
            name: "file1.txt",
            size: 500,
            fileType: .document,
            modifiedDate: testDate
        )

        let child2 = FileNode.file(
            path: URL(fileURLWithPath: "/test/dir/file2.txt"),
            name: "file2.txt",
            size: 300,
            fileType: .document,
            modifiedDate: testDate
        )

        let dirNode = FileNode.directory(
            path: URL(fileURLWithPath: "/test/dir"),
            name: "dir",
            modifiedDate: testDate,
            children: [child1, child2]
        )

        XCTAssertTrue(dirNode.isDirectory)
        XCTAssertEqual(dirNode.children.count, 2)
        XCTAssertEqual(dirNode.totalSize, 800)
        XCTAssertEqual(dirNode.fileCount, 3) // 1 directory + 2 files
    }

    func testEmptyDirectory() {
        let emptyDir = FileNode.directory(
            path: URL(fileURLWithPath: "/test/empty"),
            name: "empty",
            modifiedDate: testDate,
            children: []
        )

        XCTAssertTrue(emptyDir.isDirectory)
        XCTAssertEqual(emptyDir.children.count, 0)
        XCTAssertEqual(emptyDir.totalSize, 0)
        XCTAssertEqual(emptyDir.fileCount, 1) // Just the directory itself
    }

    func testNestedDirectoryStructure() {
        let file = FileNode.file(
            path: URL(fileURLWithPath: "/test/parent/child/file.txt"),
            name: "file.txt",
            size: 100,
            fileType: .document,
            modifiedDate: testDate
        )

        let childDir = FileNode.directory(
            path: URL(fileURLWithPath: "/test/parent/child"),
            name: "child",
            modifiedDate: testDate,
            children: [file]
        )

        let parentDir = FileNode.directory(
            path: URL(fileURLWithPath: "/test/parent"),
            name: "parent",
            modifiedDate: testDate,
            children: [childDir]
        )

        XCTAssertEqual(parentDir.children.count, 1)
        XCTAssertEqual(parentDir.children[0].children.count, 1)
        XCTAssertEqual(parentDir.totalSize, 100)
        XCTAssertEqual(parentDir.fileCount, 3) // parent + child + file
        XCTAssertEqual(parentDir.maxDepth, 2)
    }

    func testFileNodeEquality() {
        let path = URL(fileURLWithPath: "/test/file.txt")
        let node1 = FileNode.file(
            path: path,
            name: "file.txt",
            size: 1024,
            fileType: .document,
            modifiedDate: testDate
        )

        let node2 = FileNode.file(
            path: path,
            name: "file.txt",
            size: 1024,
            fileType: .document,
            modifiedDate: testDate
        )

        // Same path should be considered equal
        XCTAssertEqual(node1, node2)
        XCTAssertEqual(node1.path, node2.path)
    }

    func testLargeFile() {
        let largeFile = FileNode.file(
            path: URL(fileURLWithPath: "/test/large.dat"),
            name: "large.dat",
            size: 10_000_000_000, // 10 GB
            fileType: .other,
            modifiedDate: testDate
        )

        XCTAssertEqual(largeFile.totalSize, 10_000_000_000)
        XCTAssertEqual(largeFile.fileCount, 1)
        XCTAssertEqual(largeFile.maxDepth, 0)
    }

    func testFormattedSize() {
        let file = FileNode.file(
            path: URL(fileURLWithPath: "/test/file.txt"),
            name: "file.txt",
            size: 1500,
            fileType: .document,
            modifiedDate: testDate
        )

        // Just verify it returns a non-empty string
        XCTAssertFalse(file.formattedSize.isEmpty)
    }
}
