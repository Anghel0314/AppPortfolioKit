import Foundation

/// Public representation of an application shown in the portfolio grid.
public struct AppStoreApp: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let subtitle: String?
    public let iconURL: URL
    public let appStoreURL: URL
    public let bundleIdentifier: String?
    public let developerID: Int?

    public init(
        id: Int,
        name: String,
        subtitle: String? = nil,
        iconURL: URL,
        appStoreURL: URL,
        bundleIdentifier: String? = nil,
        developerID: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.iconURL = iconURL
        self.appStoreURL = appStoreURL
        self.bundleIdentifier = bundleIdentifier
        self.developerID = developerID
    }
}

struct LookupResponse: Decodable {
    let results: [LookupApp]
}

struct LookupApp: Decodable {
    let trackID: Int
    let trackName: String
    let description: String?
    let artworkURL512: URL?
    let artworkURL100: URL?
    let trackViewURL: URL
    let bundleID: String?
    let artistID: Int?

    enum CodingKeys: String, CodingKey {
        case trackID = "trackId"
        case trackName
        case description
        case artworkURL512 = "artworkUrl512"
        case artworkURL100 = "artworkUrl100"
        case trackViewURL = "trackViewUrl"
        case bundleID = "bundleId"
        case artistID = "artistId"
    }

    var appStoreApp: AppStoreApp? {
        guard let iconURL = artworkURL512 ?? artworkURL100 else { return nil }

        return AppStoreApp(
            id: trackID,
            name: trackName,
            subtitle: description,
            iconURL: iconURL,
            appStoreURL: trackViewURL,
            bundleIdentifier: bundleID,
            developerID: artistID
        )
    }
}
