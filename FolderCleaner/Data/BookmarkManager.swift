import Foundation

/// Manages security-scoped bookmarks and recent folder access
final class BookmarkManager {
    static let shared = BookmarkManager()

    private let userDefaults = UserDefaults.standard
    private let bookmarksKey = "SecurityScopedBookmarks"
    private let recentFoldersKey = "RecentFolders"
    private let maxRecentFolders = 10

    private init() {}

    // MARK: - Security-Scoped Bookmarks

    /// Saves a security-scoped bookmark for a URL
    /// - Parameter url: The URL to bookmark
    /// - Returns: True if the bookmark was saved successfully
    @discardableResult
    func saveBookmark(for url: URL) -> Bool {
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            var bookmarks = loadAllBookmarks()
            bookmarks[url.path] = bookmarkData
            userDefaults.set(bookmarks, forKey: bookmarksKey)

            return true
        } catch {
            print("Failed to create bookmark for \(url.path): \(error)")
            return false
        }
    }

    /// Loads a security-scoped bookmark for a URL
    /// - Parameter url: The URL to load the bookmark for
    /// - Returns: The resolved URL with security scope started, or nil if not found
    func loadBookmark(for url: URL) -> URL? {
        let bookmarks = loadAllBookmarks()

        guard let bookmarkData = bookmarks[url.path] else {
            return nil
        }

        do {
            var isStale = false
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            if isStale {
                // Recreate the bookmark if it's stale
                _ = saveBookmark(for: resolvedURL)
            }

            // Start accessing the security-scoped resource
            _ = resolvedURL.startAccessingSecurityScopedResource()

            return resolvedURL
        } catch {
            print("Failed to resolve bookmark for \(url.path): \(error)")
            return nil
        }
    }

    /// Loads all saved bookmarks
    private func loadAllBookmarks() -> [String: Data] {
        userDefaults.dictionary(forKey: bookmarksKey) as? [String: Data] ?? [:]
    }

    /// Removes a bookmark for a URL
    func removeBookmark(for url: URL) {
        var bookmarks = loadAllBookmarks()
        bookmarks.removeValue(forKey: url.path)
        userDefaults.set(bookmarks, forKey: bookmarksKey)
    }

    // MARK: - Recent Folders

    /// Adds a folder to the recent folders list
    /// - Parameter url: The folder URL to add
    func addRecentFolder(_ url: URL) {
        var recent = loadRecentFolders()

        // Remove if already exists (to move to top)
        recent.removeAll { $0 == url.path }

        // Add to beginning
        recent.insert(url.path, at: 0)

        // Keep only max items
        if recent.count > maxRecentFolders {
            recent = Array(recent.prefix(maxRecentFolders))
        }

        userDefaults.set(recent, forKey: recentFoldersKey)

        // Also save bookmark for this folder
        saveBookmark(for: url)
    }

    /// Loads the list of recent folder paths
    func loadRecentFolders() -> [String] {
        userDefaults.stringArray(forKey: recentFoldersKey) ?? []
    }

    /// Loads recent folder URLs (only those that still exist)
    func loadRecentFolderURLs() -> [URL] {
        loadRecentFolders()
            .compactMap { path -> URL? in
                let url = URL(fileURLWithPath: path)
                // Check if folder still exists
                var isDirectory: ObjCBool = false
                guard FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory),
                      isDirectory.boolValue else {
                    return nil
                }
                return url
            }
    }

    /// Clears all recent folders
    func clearRecentFolders() {
        userDefaults.removeObject(forKey: recentFoldersKey)
    }

    /// Removes a specific folder from recent folders
    func removeRecentFolder(_ url: URL) {
        var recent = loadRecentFolders()
        recent.removeAll { $0 == url.path }
        userDefaults.set(recent, forKey: recentFoldersKey)
    }
}
