import XCTest
@testable import SwiftFolderCleaner

final class ScanProgressTests: XCTestCase {
    func testInitialProgress() {
        let progress = ScanProgress.initial()

        XCTAssertEqual(progress.filesScanned, 0)
        XCTAssertEqual(progress.totalBytes, 0)
        XCTAssertEqual(progress.currentPath, "")
    }

    func testProgressWithFiles() {
        let startTime = Date()
        let progress = ScanProgress(
            filesScanned: 100,
            currentPath: "/test/path/file.txt",
            totalBytes: 1_048_576,
            startTime: startTime
        )

        XCTAssertEqual(progress.filesScanned, 100)
        XCTAssertEqual(progress.totalBytes, 1_048_576)
        XCTAssertEqual(progress.currentPath, "/test/path/file.txt")
    }

    func testFormattedBytesScanned() {
        let progress = ScanProgress(
            filesScanned: 10,
            currentPath: "/test",
            totalBytes: 1_048_576, // 1 MB
            startTime: Date()
        )

        // Should format bytes in a human-readable way
        XCTAssertFalse(progress.formattedBytesScanned.isEmpty)
        XCTAssertTrue(
            progress.formattedBytesScanned.contains("MB") ||
            progress.formattedBytesScanned.contains("MO") // French locale
        )
    }

    func testFormattedSpeed() {
        // Use a past time to ensure speed calculation works
        let startTime = Date().addingTimeInterval(-10) // 10 seconds ago
        let progress = ScanProgress(
            filesScanned: 100,
            currentPath: "/test",
            totalBytes: 10_000_000,
            startTime: startTime
        )

        // Should include speed information
        XCTAssertFalse(progress.formattedSpeed.isEmpty)
        XCTAssertTrue(progress.formattedSpeed.contains("files/s"))
        XCTAssertGreaterThan(progress.filesPerSecond, 0)
    }

    func testLargeFileCount() {
        let progress = ScanProgress(
            filesScanned: 1_000_000,
            currentPath: "/test",
            totalBytes: 100_000_000_000,
            startTime: Date()
        )

        XCTAssertEqual(progress.filesScanned, 1_000_000)
        XCTAssertEqual(progress.totalBytes, 100_000_000_000)
    }

    func testZeroProgress() {
        let progress = ScanProgress.initial()

        XCTAssertEqual(progress.filesScanned, 0)
        XCTAssertEqual(progress.totalBytes, 0)
        XCTAssertFalse(progress.formattedBytesScanned.isEmpty)
    }

    func testFormattingDifferentSizes() {
        let testCases: [(Int64, [String])] = [
            (512, ["BYTE", "B", "OCTET", "O", "512"]),  // Various formats for bytes
            (1_024, ["KB", "KO", "K"]),  // Kilobytes
            (1_048_576, ["MB", "MO", "M"]),  // Megabytes
            (1_073_741_824, ["GB", "GO", "G"]),  // Gigabytes
            (1_099_511_627_776, ["TB", "TO", "T"])  // Terabytes
        ]

        for (bytes, possibleUnits) in testCases {
            let progress = ScanProgress(
                filesScanned: 1,
                currentPath: "/test",
                totalBytes: bytes,
                startTime: Date()
            )
            let formatted = progress.formattedBytesScanned.uppercased()

            // Check that the formatted string contains at least one of the expected units
            let containsExpectedUnit = possibleUnits.contains { formatted.contains($0) }
            XCTAssertTrue(
                containsExpectedUnit,
                "Failed for bytes: \(bytes), expected one of: \(possibleUnits), got: \(formatted)"
            )
        }
    }

    func testUpdateProgress() {
        let initial = ScanProgress.initial()
        let updated = initial.update(path: "/test/file.txt", fileSize: 1000)

        XCTAssertEqual(updated.filesScanned, 1)
        XCTAssertEqual(updated.totalBytes, 1000)
        XCTAssertEqual(updated.currentPath, "/test/file.txt")

        // Start time should be preserved
        XCTAssertEqual(updated.startTime, initial.startTime)
    }

    func testIndeterminateProgress() {
        let progress = ScanProgress.initial()

        // File system scanning has indeterminate progress
        XCTAssertEqual(progress.percentage, -1.0)
        XCTAssertNil(progress.estimatedTimeRemaining)
    }
}
