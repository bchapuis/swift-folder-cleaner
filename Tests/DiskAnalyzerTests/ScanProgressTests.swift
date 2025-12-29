import XCTest
@testable import FolderCleaner

final class ScanProgressTests: XCTestCase {
    func testInitialProgress() {
        let progress = ScanProgress(filesScanned: 0, bytesScanned: 0)

        XCTAssertEqual(progress.filesScanned, 0)
        XCTAssertEqual(progress.bytesScanned, 0)
    }

    func testProgressWithFiles() {
        let progress = ScanProgress(filesScanned: 100, bytesScanned: 1_048_576)

        XCTAssertEqual(progress.filesScanned, 100)
        XCTAssertEqual(progress.bytesScanned, 1_048_576)
    }

    func testFormattedBytesScanned() {
        let progress = ScanProgress(filesScanned: 10, bytesScanned: 1_048_576) // 1 MB

        // Should format bytes in a human-readable way
        XCTAssertFalse(progress.formattedBytesScanned.isEmpty)
        XCTAssertTrue(
            progress.formattedBytesScanned.contains("MB") ||
            progress.formattedBytesScanned.contains("MO") // French locale
        )
    }

    func testFormattedSpeed() {
        let progress = ScanProgress(filesScanned: 100, bytesScanned: 10_000_000)

        // Should include speed information
        XCTAssertFalse(progress.formattedSpeed.isEmpty)
    }

    func testLargeFileCount() {
        let progress = ScanProgress(filesScanned: 1_000_000, bytesScanned: 100_000_000_000)

        XCTAssertEqual(progress.filesScanned, 1_000_000)
        XCTAssertEqual(progress.bytesScanned, 100_000_000_000)
    }

    func testZeroProgress() {
        let progress = ScanProgress(filesScanned: 0, bytesScanned: 0)

        XCTAssertEqual(progress.filesScanned, 0)
        XCTAssertEqual(progress.bytesScanned, 0)
        XCTAssertFalse(progress.formattedBytesScanned.isEmpty)
    }

    func testFormattingDifferentSizes() {
        let testCases: [(Int64, String)] = [
            (512, "bytes"),
            (1_024, "KB"),
            (1_048_576, "MB"),
            (1_073_741_824, "GB"),
            (1_099_511_627_776, "TB")
        ]

        for (bytes, expectedUnit) in testCases {
            let progress = ScanProgress(filesScanned: 1, bytesScanned: bytes)
            let formatted = progress.formattedBytesScanned.uppercased()

            // Check that the formatted string contains the expected unit (case insensitive)
            XCTAssertTrue(
                formatted.contains(expectedUnit) ||
                formatted.contains(expectedUnit.replacingOccurrences(of: "B", with: "O")), // French locale
                "Failed for bytes: \(bytes), expected unit: \(expectedUnit), got: \(formatted)"
            )
        }
    }
}
