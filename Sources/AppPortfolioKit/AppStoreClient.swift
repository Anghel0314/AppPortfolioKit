import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum AppStoreClientError: Error, LocalizedError, Sendable {
    case noAppIDs
    case invalidResponse
    case requestFailed(statusCode: Int)

    public var errorDescription: String? {
        switch self {
        case .noAppIDs:
            "No App Store IDs were provided."
        case .invalidResponse:
            "The App Store returned an invalid response."
        case let .requestFailed(statusCode):
            "The App Store request failed with status code \(statusCode)."
        }
    }
}

/// Loads public metadata from Apple's iTunes Lookup API.
public struct AppStoreClient: Sendable {
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    public func apps(ids: [Int], countryCode: String? = nil) async throws -> [AppStoreApp] {
        let uniqueIDs = ids.reduce(into: [Int]()) { result, id in
            guard id > 0, !result.contains(id) else { return }
            result.append(id)
        }
        guard !uniqueIDs.isEmpty else { throw AppStoreClientError.noAppIDs }

        let requestURL = try Self.lookupURL(ids: uniqueIDs, countryCode: countryCode)
        let (data, response) = try await session.data(from: requestURL)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppStoreClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw AppStoreClientError.requestFailed(statusCode: httpResponse.statusCode)
        }

        let payload = try decoder.decode(LookupResponse.self, from: data)
        let appsByID = Dictionary(
            uniqueKeysWithValues: payload.results.compactMap { result in
                result.appStoreApp.map { ($0.id, $0) }
            }
        )

        // Apple does not promise response ordering, so preserve the order chosen by the host app.
        return uniqueIDs.compactMap { appsByID[$0] }
    }

    static func lookupURL(ids: [Int], countryCode: String?) throws -> URL {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems = [
            URLQueryItem(name: "id", value: ids.map(String.init).joined(separator: ",")),
            URLQueryItem(name: "entity", value: "software")
        ]

        if let countryCode {
            let normalizedCode = countryCode.trimmingCharacters(in: .whitespacesAndNewlines)
            if !normalizedCode.isEmpty {
                queryItems.append(URLQueryItem(name: "country", value: normalizedCode.lowercased()))
            }
        }

        components?.queryItems = queryItems
        guard let url = components?.url else { throw AppStoreClientError.invalidResponse }
        return url
    }
}
