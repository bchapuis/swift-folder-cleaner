import XCTest
@testable import DiskAnalyzer

@MainActor
final class FileScannerTests: XCTestCase {
    var testDirectory: URL!

    override func setUp() async throws {
        // Create a temporary test directory
        testDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DiskAnalyzerTests")
            .appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(
            at: testDirectory,
            withIntermediateDirectories: true
        )

        // Create test files
        try createTestStructure()
    }

    override func tearDown() async throws {
        // Clean up test directory
        if FileManager.default.fileExists(atPath: testDirectory.path) {
            try FileManager.default.removeItem(at: testDirectory)
        }
    }

    func testScanEmptyDirectory() async throws {
        let emptyDir = testDirectory.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: emptyDir, withIntermediateDirectories: true)

        let scanner = AsyncFileScanner()
        let result = try await scanner.scan(url: emptyDir)

        XCTAssertEqual(result.rootNode.name, "empty")
        XCTAssertTrue(result.rootNode.isDirectory)
        XCTAssertEqual(result.rootNode.children.count, 0)
    }

    func testScanDirectoryWithFiles() async throws {
        let scanner = AsyncFileScanner()
        let result = try await scanner.scan(url: testDirectory)

        XCTAssertTrue(result.rootNode.isDirectory)
        XCTAssertGreaterThan(result.rootNode.children.count, 0)
        XCTAssertGreaterThan(result.totalSize, 0)
        XCTAssertGreaterThan(result.totalFilesScanned, 0)
    }

    func testFileTypeDetection() async throws {
        let scanner = AsyncFileScanner()
        let result = try await scanner.scan(url: testDirectory)

        // Find the test files
        let imageFile = findNode(in: result.rootNode, named: "test.png")
        let codeFile = findNode(in: result.rootNode, named: "test.swift")
        let textFile = findNode(in: result.rootNode, named: "test.txt")

        XCTAssertEqual(imageFile?.fileType, .image)
        XCTAssertEqual(codeFile?.fileType, .code)
        XCTAssertEqual(textFile?.fileType, .document)
    }

    func testProgressTracking() async throws {
        let scanner = AsyncFileScanner()
        var progressUpdates: [ScanProgress] = []

        _ = try await scanner.scan(url: testDirectory) { progress in
            progressUpdates.append(progress)
        }

        XCTAssertGreaterThan(progressUpdates.count, 0)
        XCTAssertGreaterThan(progressUpdates.last?.filesScanned ?? 0, 0)
    }

    func testCancellation() async throws {
        let scanner = AsyncFileScanner()

        let task = Task {
            try await scanner.scan(url: testDirectory)
        }

        // Cancel immediately
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Should have thrown cancellation error")
        } catch let error as ScanError {
            XCTAssertEqual(error, .cancelled)
        }
    }

    func testInvalidPath() async throws {
        let scanner = AsyncFileScanner()
        let invalidPath = testDirectory.appendingPathComponent("nonexistent")

        do {
            _ = try await scanner.scan(url: invalidPath)
            XCTFail("Should have thrown path not found error")
        } catch let error as ScanError {
            if case .pathNotFound = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        }
    }

    // MARK: - Helper Methods

    private func createTestStructure() throws {
        // Create some directories
        let docsDir = testDirectory.appendingPathComponent("documents")
        let imagesDir = testDirectory.appendingPathComponent("images")
        let codeDir = testDirectory.appendingPathComponent("code")

        for dir in [docsDir, imagesDir, codeDir] {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Create test files
        try "Hello World".write(to: docsDir.appendingPathComponent("test.txt"), atomically: true, encoding: .utf8)
        try "func test() {}".write(to: codeDir.appendingPathComponent("test.swift"), atomically: true, encoding: .utf8)

        // Create a dummy image file
        let imageData = Data([0x89, 0x50, 0x4E, 0x47])  // PNG header
        try imageData.write(to: imagesDir.appendingPathComponent("test.png"))
    }

    private func findNode(in node: FileNode, named name: String) -> FileNode? {
        if node.name == name {
            return node
        }

        for child in node.children {
            if let found = findNode(in: child, named: name) {
                return found
            }
        }

        return nil
    }
}

extension ScanError: Equatable {
    public static func == (lhs: ScanError, rhs: ScanError) -> Bool {
        switch (lhs, rhs) {
        case (.cancelled, .cancelled):
            return true
        case let (.permissionDenied(p1), .permissionDenied(p2)):
            return p1 == p2
        case let (.pathNotFound(p1), .pathNotFound(p2)):
            return p1 == p2
        case let (.notADirectory(p1), .notADirectory(p2)):
            return p1 == p2
        case let (.unknown(e1), .unknown(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}
