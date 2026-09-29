import Foundation

// MARK: - Error Types
public enum FPLError: LocalizedError, Equatable {
    case invalidURL
    case networkError(String)
    case invalidResponse(statusCode: Int)
    case decodingError(String)
    case noCachedData

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The FPL API endpoint URL is invalid."
        case .networkError(let message):
            return "Network connection error: \(message)"
        case .invalidResponse(let statusCode):
            return "Server responded with status code \(statusCode)."
        case .decodingError(let message):
            return "Failed to parse data: \(message)"
        case .noCachedData:
            return "No offline data available. Please connect to the internet."
        }
    }
}

// MARK: - Service Protocol
public protocol FPLServiceProtocol: Sendable {
    func fetchBootstrapData() async throws -> FPLBootstrapData
}

// MARK: - Service Implementation
public final class FPLService: FPLServiceProtocol {
    private let session: URLSession
    private let endpointURLString: String

    public init(
        session: URLSession = .shared,
        endpointURLString: String = "https://fantasy.premierleague.com/api/bootstrap-static/"
    ) {
        self.session = session
        self.endpointURLString = endpointURLString
    }

    public func fetchBootstrapData() async throws -> FPLBootstrapData {
        guard let url = URL(string: endpointURLString) else {
            throw FPLError.invalidURL
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw FPLError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FPLError.networkError("Invalid server response.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw FPLError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(FPLBootstrapData.self, from: data)
        } catch {
            throw FPLError.decodingError(error.localizedDescription)
        }
    }
}
