import Foundation

// MARK: - Repository Protocol

public protocol FPLRepositoryProtocol: Sendable {
    /// Loads static data from the network, falling back to disk cache if offline.
    func loadData(forceRefresh: Bool) async throws -> FPLBootstrapData
    
    /// Returns the currently cached bootstrap data from disk, if available.
    func getCachedData() -> FPLBootstrapData?
}

// MARK: - Repository Implementation

public final class FPLRepository: FPLRepositoryProtocol {
    private let service: FPLServiceProtocol
    private let cache: FPLCacheProtocol

    public init(
        service: FPLServiceProtocol = FPLService(),
        cache: FPLCacheProtocol = FPLFileCache()
    ) {
        self.service = service
        self.cache = cache
    }

    /// Retrieves cached bootstrap data from local disk.
    public func getCachedData() -> FPLBootstrapData? {
        return cache.loadCachedData()
    }

    /// Fetches bootstrap data from the network, saving to disk and falling back to cache on failure.
    public func loadData(forceRefresh: Bool) async throws -> FPLBootstrapData {
        if forceRefresh {
            let freshData = try await service.fetchBootstrapData()
            try? cache.saveCachedData(freshData)
            return freshData
        }

        do {
            let freshData = try await service.fetchBootstrapData()
            try? cache.saveCachedData(freshData)
            return freshData
        } catch {
            if let cachedData = cache.loadCachedData() {
                return cachedData
            }
            throw error
        }
    }
}
