import Foundation
import CryptoKit

/// Represents a group of duplicate files
struct DuplicateGroup: Identifiable {
    let id = UUID()
    let files: [FileNode]
    let size: Int64
    let hash: String

    var wastedSpace: Int64 {
        // All but one file is wasted space
        size * Int64(max(0, files.count - 1))
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var formattedWaste: String {
        ByteCountFormatter.string(fromByteCount: wastedSpace, countStyle: .file)
    }
}

/// Finds duplicate files based on size and content hash
actor DuplicateFinder {

    /// Progress callback for duplicate finding
    typealias ProgressHandler = @Sendable (Int, Int) -> Void

    /// Find all duplicate files in the tree
    func findDuplicates(
        in rootNode: FileNode,
        progress: ProgressHandler? = nil
    ) async -> [DuplicateGroup] {
        // Step 1: Collect all files
        var allFiles: [FileNode] = []
        collectFiles(node: rootNode, files: &allFiles)

        // Step 2: Group by size (quick check)
        var sizeGroups: [Int64: [FileNode]] = [:]
        for file in allFiles {
            sizeGroups[file.totalSize, default: []].append(file)
        }

        // Step 3: Filter to only sizes with duplicates
        let potentialDuplicates = sizeGroups.filter { $0.value.count > 1 }

        // Step 4: Calculate hashes for potential duplicates
        var duplicateGroups: [DuplicateGroup] = []
        var processedCount = 0
        let totalFiles = potentialDuplicates.values.flatMap { $0 }.count

        for (size, files) in potentialDuplicates {
            // Group by hash
            var hashGroups: [String: [FileNode]] = [:]

            for file in files {
                // Calculate hash
                if let hash = await calculateHash(for: file.path) {
                    hashGroups[hash, default: []].append(file)
                }

                processedCount += 1
                await progress?(processedCount, totalFiles)
            }

            // Add groups with actual duplicates
            for (hash, duplicateFiles) in hashGroups where duplicateFiles.count > 1 {
                duplicateGroups.append(DuplicateGroup(
                    files: duplicateFiles,
                    size: size,
                    hash: hash
                ))
            }
        }

        // Sort by wasted space (descending)
        return duplicateGroups.sorted { $0.wastedSpace > $1.wastedSpace }
    }

    private func collectFiles(node: FileNode, files: inout [FileNode]) {
        if !node.isDirectory {
            files.append(node)
        }

        for child in node.children {
            collectFiles(node: child, files: &files)
        }
    }

    /// Calculate SHA-256 hash of a file
    private func calculateHash(for url: URL) async -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            // Read file in chunks to handle large files
            let bufferSize = 1024 * 1024 // 1MB chunks
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }

            var hasher = SHA256()

            while autoreleasepool(invoking: {
                guard let chunk = try? file.read(upToCount: bufferSize),
                      !chunk.isEmpty else {
                    return false
                }
                hasher.update(data: chunk)
                return true
            }) {}

            let digest = hasher.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()

        } catch {
            return nil
        }
    }
}
