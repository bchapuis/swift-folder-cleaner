import XCTest
@testable import FolderCleaner

@MainActor
final class FileOperationsIntegrationTests: XCTestCase {
    var testDirectory: URL!
    var fileOperations: FileOperationsService!

    override func setUp() async throws {
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("FileOperationsTests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: testDirectory,
            withIntermediateDirectories: true
        )

        fileOperations = FileOperationsService()
        try await createTestFiles()
    }

    override func tearDown() async throws {
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
    }

    func testMoveFileToTrash() async throws {
        let testFile = testDirectory.appendingPathComponent("test.txt")
        try "Test content".write(to: testFile, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile.path))

        try await fileOperations.moveToTrash(url: testFile)

        // File should no longer exist at original location
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile.path))
    }

    func testMoveDirectoryToTrash() async throws {
        let testDir = testDirectory.appendingPathComponent("testdir")
        try FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

        let fileInDir = testDir.appendingPathComponent("file.txt")
        try "Content".write(to: fileInDir, atomically: true, encoding: .utf8)

        XCTAssertTrue(FileManager.default.fileExists(atPath: testDir.path))

        try await fileOperations.moveToTrash(url: testDir)

        // Directory should no longer exist
        XCTAssertFalse(FileManager.default.fileExists(atPath: testDir.path))
    }

    func testMoveNonexistentFileToTrash() async throws {
        let nonexistent = testDirectory.appendingPathComponent("nonexistent.txt")

        do {
            try await fileOperations.moveToTrash(url: nonexistent)
            XCTFail("Should throw error for nonexistent file")
        } catch {
            // Expected to throw
        }
    }

    func testRevealInFinder() throws {
        let testFile = testDirectory.appendingPathComponent("reveal.txt")
        try "Test".write(to: testFile, atomically: true, encoding: .utf8)

        // This should not throw
        XCTAssertNoThrow(try FileActions.revealInFinder(url: testFile))
    }

    func testScanAndDeleteLargeFile() async throws {
        let largeFile = testDirectory.appendingPathComponent("large.dat")
        let data = Data(repeating: 0, count: 10_000_000) // 10 MB
        try data.write(to: largeFile)

        let scanner = AsyncFileScanner()
        let result = try await scanner.scan(url: testDirectory)

        // Find the large file in results
        let foundFile = findFile(named: "large.dat", in: result.rootNode)
        XCTAssertNotNil(foundFile)
        XCTAssertEqual(foundFile?.totalSize, 10_000_000)

        // Delete it
        try await fileOperations.moveToTrash(url: largeFile)
        XCTAssertFalse(FileManager.default.fileExists(atPath: largeFile.path))
    }

    func testScanFilterAndDelete() async throws {
        // Create files of different types
        let imageFile = testDirectory.appendingPathComponent("photo.jpg")
        let videoFile = testDirectory.appendingPathComponent("video.mp4")
        let textFile = testDirectory.appendingPathComponent("doc.txt")

        try Data([0x89, 0x50, 0x4E, 0x47]).write(to: imageFile)
        try Data(repeating: 0, count: 1000).write(to: videoFile)
        try "Text".write(to: textFile, atomically: true, encoding: .utf8)

        // Scan
        let scanner = AsyncFileScanner()
        let result = try await scanner.scan(url: testDirectory)

        // Filter for images only
        var filter = FileTreeFilter()
        filter.enabledFileTypes = [.image]
        let filtered = filter.apply(to: result.rootNode)

        // Should only have image file
        let imageFiles = filtered.children.filter { $0.fileType == .image }
        XCTAssertEqual(imageFiles.count, 1)
        XCTAssertEqual(imageFiles[0].name, "photo.jpg")

        // Delete the image
        try await fileOperations.moveToTrash(url: imageFile)
        XCTAssertFalse(FileManager.default.fileExists(atPath: imageFile.path))

        // Other files should still exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: videoFile.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: textFile.path))
    }

    func testConcurrentFileOperations() async throws {
        // Create multiple test files
        let files = (0..<10).map {
            testDirectory.appendingPathComponent("file\($0).txt")
        }

        for file in files {
            try "Content".write(to: file, atomically: true, encoding: .utf8)
        }

        // Delete them concurrently
        try await withThrowingTaskGroup(of: Void.self) { group in
            for file in files {
                group.addTask {
                    try await self.fileOperations.moveToTrash(url: file)
                }
            }

            try await group.waitForAll()
        }

        // All files should be deleted
        for file in files {
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        }
    }

    // MARK: - Helper Methods

    private func createTestFiles() async throws {
        let file1 = testDirectory.appendingPathComponent("test1.txt")
        let file2 = testDirectory.appendingPathComponent("test2.swift")

        try "Test 1".write(to: file1, atomically: true, encoding: .utf8)
        try "func test() {}".write(to: file2, atomically: true, encoding: .utf8)
    }

    private func findFile(named name: String, in node: FileNode) -> FileNode? {
        if node.name == name {
            return node
        }

        for child in node.children {
            if let found = findFile(named: name, in: child) {
                return found
            }
        }

        return nil
    }
}
