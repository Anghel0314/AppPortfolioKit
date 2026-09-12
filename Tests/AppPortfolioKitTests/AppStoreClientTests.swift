import Foundation
import Testing
@testable import AppPortfolioKit

@Test func lookupURLContainsIDsAndCountry() throws {
    let url = try AppStoreClient.lookupURL(ids: [123, 456], countryCode: " US ")
    let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    let items = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).compactMap { item in
        item.value.map { (item.name, $0) }
    })

    #expect(components.scheme == "https")
    #expect(components.host == "itunes.apple.com")
    #expect(items["id"] == "123,456")
    #expect(items["entity"] == "software")
    #expect(items["country"] == "us")
}

@Test func lookupResponseDecodesApp() throws {
    let json = #"""
    {
      "resultCount": 1,
      "results": [{
        "trackId": 123,
        "trackName": "Example",
        "description": "An example app",
        "artworkUrl100": "https://example.com/icon.png",
        "trackViewUrl": "https://apps.apple.com/app/id123",
        "bundleId": "com.example.app",
        "artistId": 456
      }]
    }
    """#.data(using: .utf8)!

    let response = try JSONDecoder().decode(LookupResponse.self, from: json)
    let app = try #require(response.results.first?.appStoreApp)

    #expect(app.id == 123)
    #expect(app.name == "Example")
    #expect(app.bundleIdentifier == "com.example.app")
    #expect(app.developerID == 456)
}

@Test func manifestDecodesAppIDs() throws {
    let json = #"{"appIDs":[6799032467,6753864943]}"#.data(using: .utf8)!
    let manifest = try JSONDecoder().decode(AppPortfolioManifest.self, from: json)

    #expect(manifest.appIDs == [6799032467, 6753864943])
}
