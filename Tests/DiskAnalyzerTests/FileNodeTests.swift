import XCTest
@testable import FolderCleaner

final class FileNodeTests: XCTestCase {
    func testFileNodeCreation() {
        let fileNode = FileNode(
            path: URL(fileURLWithPath: "/test/file.txt"),
            name: "file.txt",
            totalSize: 1024,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        XCTAssertEqual(fileNode.name, "file.txt")
        XCTAssertEqual(fileNode.totalSize, 1024)
        XCTAssertFalse(fileNode.isDirectory)
        XCTAssertEqual(fileNode.fileType, .document)
        XCTAssertEqual(fileNode.children.count, 0)
    }

    func testDirectoryNodeWithChildren() {
        let child1 = FileNode(
            path: URL(fileURLWithPath: "/test/dir/file1.txt"),
            name: "file1.txt",
            totalSize: 500,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let child2 = FileNode(
            path: URL(fileURLWithPath: "/test/dir/file2.txt"),
            name: "file2.txt",
            totalSize: 300,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let dirNode = FileNode(
            path: URL(fileURLWithPath: "/test/dir"),
            name: "dir",
            totalSize: 800,
            isDirectory: true,
            fileType: .other,
            children: [child1, child2]
        )

        XCTAssertTrue(dirNode.isDirectory)
        XCTAssertEqual(dirNode.children.count, 2)
        XCTAssertEqual(dirNode.totalSize, 800)
    }

    func testEmptyDirectory() {
        let emptyDir = FileNode(
            path: URL(fileURLWithPath: "/test/empty"),
            name: "empty",
            totalSize: 0,
            isDirectory: true,
            fileType: .other,
            children: []
        )

        XCTAssertTrue(emptyDir.isDirectory)
        XCTAssertEqual(emptyDir.children.count, 0)
        XCTAssertEqual(emptyDir.totalSize, 0)
    }

    func testNestedDirectoryStructure() {
        let file = FileNode(
            path: URL(fileURLWithPath: "/test/parent/child/file.txt"),
            name: "file.txt",
            totalSize: 100,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let childDir = FileNode(
            path: URL(fileURLWithPath: "/test/parent/child"),
            name: "child",
            totalSize: 100,
            isDirectory: true,
            fileType: .other,
            children: [file]
        )

        let parentDir = FileNode(
            path: URL(fileURLWithPath: "/test/parent"),
            name: "parent",
            totalSize: 100,
            isDirectory: true,
            fileType: .other,
            children: [childDir]
        )

        XCTAssertEqual(parentDir.children.count, 1)
        XCTAssertEqual(parentDir.children[0].children.count, 1)
        XCTAssertEqual(parentDir.totalSize, 100)
    }

    func testFileNodeEquality() {
        let path = URL(fileURLWithPath: "/test/file.txt")
        let node1 = FileNode(
            path: path,
            name: "file.txt",
            totalSize: 1024,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        let node2 = FileNode(
            path: path,
            name: "file.txt",
            totalSize: 1024,
            isDirectory: false,
            fileType: .document,
            children: []
        )

        // Same path should be considered equal
        XCTAssertEqual(node1.path, node2.path)
    }

    func testLargeFile() {
        let largeFile = FileNode(
            path: URL(fileURLWithPath: "/test/large.dat"),
            name: "large.dat",
            totalSize: 10_000_000_000, // 10 GB
            isDirectory: false,
            fileType: .other,
            children: []
        )

        XCTAssertEqual(largeFile.totalSize, 10_000_000_000)
    }
}
