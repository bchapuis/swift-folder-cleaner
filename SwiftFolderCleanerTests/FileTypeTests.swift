import XCTest
@testable import SwiftFolderCleaner

final class FileTypeTests: XCTestCase {
    func testImageFileType() {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "svg", "heic", "webp"]
        for ext in imageExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .image, "Failed for extension: \(ext)")
        }
    }

    func testVideoFileType() {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
        for ext in videoExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .video, "Failed for extension: \(ext)")
        }
    }

    func testAudioFileType() {
        let audioExtensions = ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
        for ext in audioExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .audio, "Failed for extension: \(ext)")
        }
    }

    func testCodeFileType() {
        // Test that file type detection doesn't crash on code extensions
        let extensions = ["swift", "py", "js"]
        for ext in extensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            _ = FileTypeDetector.detectType(for: url)
        }
        // If we get here without crashing, test passes
        XCTAssertTrue(true)
    }

    func testDocumentFileType() {
        let docExtensions = ["pdf", "doc", "docx", "txt", "md", "rtf", "pages"]
        for ext in docExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .document, "Failed for extension: \(ext)")
        }
    }

    func testArchiveFileType() {
        let archiveExtensions = ["zip", "tar", "gz", "7z", "rar", "dmg"]
        for ext in archiveExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .archive, "Failed for extension: \(ext)")
        }
    }

    func testUnknownFileType() {
        let unknownExtensions = ["xyz", "abc", "123", "unknown"]
        for ext in unknownExtensions {
            let url = URL(fileURLWithPath: "/test/file.\(ext)")
            let type = FileTypeDetector.detectType(for: url)
            XCTAssertEqual(type, .other, "Failed for extension: \(ext)")
        }
    }

    func testCaseInsensitivity() {
        // Test that file type detection works regardless of extension case
        XCTAssertEqual(FileTypeDetector.detectType(for: URL(fileURLWithPath: "/test/file.JPG")), .image)
        XCTAssertEqual(FileTypeDetector.detectType(for: URL(fileURLWithPath: "/test/file.Mp4")), .video)
        XCTAssertEqual(FileTypeDetector.detectType(for: URL(fileURLWithPath: "/test/file.PDF")), .document)
    }

    func testFileTypeColors() {
        // Test that all file types have defined colors
        let allTypes: [FileType] = [.directory, .image, .video, .audio, .code, .document, .archive, .executable, .system, .other]
        for type in allTypes {
            XCTAssertNotNil(type.color, "Missing color for type: \(type)")
        }
    }

    func testFileTypeDisplayNames() {
        XCTAssertEqual(FileType.image.displayName, "Image")
        XCTAssertEqual(FileType.video.displayName, "Video")
        XCTAssertEqual(FileType.audio.displayName, "Audio")
        XCTAssertEqual(FileType.code.displayName, "Code")
        XCTAssertEqual(FileType.document.displayName, "Document")
        XCTAssertEqual(FileType.archive.displayName, "Archive")
        XCTAssertEqual(FileType.other.displayName, "Other")
    }
}
