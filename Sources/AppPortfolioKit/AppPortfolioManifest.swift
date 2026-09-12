import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A remotely managed list of App Store identifiers.
public struct AppPortfolioManifest: Codable, Equatable, Sendable {
    public let appIDs: [Int]

    public init(appIDs: [Int]) {
        self.appIDs = appIDs
    }
}

public enum AppPortfolioManifestError: Error, LocalizedError, Sendable {
    case invalidResponse
    case requestFailed(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "The app portfolio manifest returned an invalid response."
        case let .requestFailed(statusCode):
            "The app portfolio manifest request failed with status code \(statusCode)."
        }
    }
}

/// Downloads an app list without relying on the device's URL cache, so changes
/// to a hosted manifest can reach installed applications without an app update.
public struct AppPortfolioManifestClient: Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func appIDs(from url: URL) async throws -> [Int] {
        var request = URLRequest(
            url: cacheBustedURL(from: url),
            cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: 15
        )
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-cache", forHTTPHeaderField: "Pragma")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppPortfolioManifestError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppPortfolioManifestError.requestFailed(statusCode: httpResponse.statusCode)
        }

        return try decoder.decode(AppPortfolioManifest.self, from: data).appIDs
    }

    private func cacheBustedURL(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        var queryItems = components.queryItems ?? []
        queryItems.removeAll { $0.name == "appPortfolioRefresh" }
        queryItems.append(
            URLQueryItem(
                name: "appPortfolioRefresh",
                value: String(Int(Date().timeIntervalSince1970))
            )
        )
        components.queryItems = queryItems
        return components.url ?? url
    }
}
