import XCTest
@testable import FolderCleaner

final class FileTypeTests: XCTestCase {
    func testImageFileType() {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "svg", "heic", "webp"]
        for ext in imageExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .image, "Failed for extension: \(ext)")
        }
    }

    func testVideoFileType() {
        let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "m4v"]
        for ext in videoExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .video, "Failed for extension: \(ext)")
        }
    }

    func testAudioFileType() {
        let audioExtensions = ["mp3", "wav", "flac", "aac", "ogg", "m4a"]
        for ext in audioExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .audio, "Failed for extension: \(ext)")
        }
    }

    func testCodeFileType() {
        let codeExtensions = ["swift", "py", "js", "java", "cpp", "c", "h", "ts", "go", "rs"]
        for ext in codeExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .code, "Failed for extension: \(ext)")
        }
    }

    func testDocumentFileType() {
        let docExtensions = ["pdf", "doc", "docx", "txt", "md", "rtf", "pages"]
        for ext in docExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .document, "Failed for extension: \(ext)")
        }
    }

    func testArchiveFileType() {
        let archiveExtensions = ["zip", "tar", "gz", "7z", "rar", "dmg"]
        for ext in archiveExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .archive, "Failed for extension: \(ext)")
        }
    }

    func testUnknownFileType() {
        let unknownExtensions = ["xyz", "abc", "123", "unknown"]
        for ext in unknownExtensions {
            let type = FileTypeDetector.detectFileType(extension: ext, path: "/test/file.\(ext)")
            XCTAssertEqual(type, .other, "Failed for extension: \(ext)")
        }
    }

    func testCaseInsensitivity() {
        XCTAssertEqual(FileTypeDetector.detectFileType(extension: "JPG", path: "/test/file.JPG"), .image)
        XCTAssertEqual(FileTypeDetector.detectFileType(extension: "Mp4", path: "/test/file.Mp4"), .video)
        XCTAssertEqual(FileTypeDetector.detectFileType(extension: "SWIFT", path: "/test/file.SWIFT"), .code)
    }

    func testFileTypeColors() {
        // Test that all file types have defined colors
        let allTypes: [FileType] = [.image, .video, .audio, .code, .document, .archive, .other]
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
