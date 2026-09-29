import Foundation

// MARK: - Cache Protocol
public protocol FPLCacheProtocol: Sendable {
    func loadCachedData() -> FPLBootstrapData?
    func saveCachedData(_ data: FPLBootstrapData) throws
    func clearCache()
}

// MARK: - File-Based Cache Implementation
public final class FPLFileCache: FPLCacheProtocol {
    private let fileURL: URL
    private let fileManager: FileManager

    public init(
        fileURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager
        if let fileURL = fileURL {
            self.fileURL = fileURL
        } else {
            let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.fileURL = directory.appendingPathComponent("fpl_bootstrap_cache.json")
        }
    }

    public func loadCachedData() -> FPLBootstrapData? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(FPLBootstrapData.self, from: data)
        } catch {
            return nil
        }
    }

    public func saveCachedData(_ data: FPLBootstrapData) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let encodedData = try encoder.encode(data)
        try encodedData.write(to: fileURL, options: .atomic)
    }

    public func clearCache() {
        try? fileManager.removeItem(at: fileURL)
    }
}
