import SwiftUI

/// A reusable grid of App Store applications. Metadata and icons are loaded from Apple.
public struct AppPortfolioView: View {
    private let appIDs: [Int]
    private let manifestURL: URL?
    private let countryCode: String?
    private let configuration: AppPortfolioConfiguration
    private let client: AppStoreClient
    private let manifestClient: AppPortfolioManifestClient

    @State private var state: LoadingState = .loading

    public init(
        appIDs: [Int],
        countryCode: String? = Locale.current.region?.identifier,
        configuration: AppPortfolioConfiguration = .default,
        client: AppStoreClient = AppStoreClient(),
        manifestClient: AppPortfolioManifestClient = AppPortfolioManifestClient()
    ) {
        self.appIDs = appIDs
        self.manifestURL = nil
        self.countryCode = countryCode
        self.configuration = configuration
        self.client = client
        self.manifestClient = manifestClient
    }

    /// Creates a portfolio backed by a remotely hosted JSON manifest.
    /// `fallbackAppIDs` are used when the manifest cannot be downloaded.
    public init(
        manifestURL: URL,
        fallbackAppIDs: [Int] = [],
        countryCode: String? = Locale.current.region?.identifier,
        configuration: AppPortfolioConfiguration = .default,
        client: AppStoreClient = AppStoreClient(),
        manifestClient: AppPortfolioManifestClient = AppPortfolioManifestClient()
    ) {
        self.appIDs = fallbackAppIDs
        self.manifestURL = manifestURL
        self.countryCode = countryCode
        self.configuration = configuration
        self.client = client
        self.manifestClient = manifestClient
    }

    public var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Loading apps")
            case let .loaded(apps):
                if !apps.isEmpty {
                    portfolio(apps)
                }
            case .failed:
                Button("Try again") {
                    state = .loading
                    Task { await loadApps() }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .task(id: LoadKey(appIDs: appIDs, manifestURL: manifestURL, countryCode: countryCode)) {
            await loadApps()
        }
    }

    @ViewBuilder
    private func portfolio(_ apps: [AppStoreApp]) -> some View {
        VStack(alignment: .leading, spacing: configuration.spacing) {
            if let title = configuration.title, !title.isEmpty {
                Text(title)
                    .font(.headline)
            }

            LazyVGrid(columns: columns, spacing: configuration.spacing) {
                ForEach(apps) { app in
                    Link(destination: app.appStoreURL) {
                        AppTile(app: app, configuration: configuration)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(app.name)
                    .accessibilityHint("Opens in the App Store")
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: configuration.spacing),
            count: configuration.columns
        )
    }

    @MainActor
    private func loadApps() async {
        do {
            let resolvedIDs: [Int]
            if let manifestURL {
                resolvedIDs = (try? await manifestClient.appIDs(from: manifestURL)) ?? appIDs
            } else {
                resolvedIDs = appIDs
            }

            var apps = try await client.apps(ids: resolvedIDs, countryCode: countryCode)
            if let allowedDeveloperID = configuration.allowedDeveloperID {
                apps.removeAll { $0.developerID != allowedDeveloperID }
            }
            if configuration.excludesCurrentApp,
               let currentBundleID = Bundle.main.bundleIdentifier {
                apps.removeAll { $0.bundleIdentifier == currentBundleID }
            }
            guard !Task.isCancelled else { return }
            state = .loaded(apps)
        } catch is CancellationError {
            // A newer task replaced this request.
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed
        }
    }
}

private extension AppPortfolioView {
    enum LoadingState {
        case loading
        case loaded([AppStoreApp])
        case failed
    }

    struct LoadKey: Hashable {
        let appIDs: [Int]
        let manifestURL: URL?
        let countryCode: String?
    }
}

private struct AppTile: View {
    let app: AppStoreApp
    let configuration: AppPortfolioConfiguration

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: app.iconURL) { phase in
                switch phase {
                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                case .failure:
                    Image(systemName: "app.dashed")
                        .resizable()
                        .scaledToFit()
                        .padding(configuration.iconSize * 0.2)
                        .foregroundStyle(.secondary)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: configuration.iconSize, height: configuration.iconSize)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: configuration.iconSize * 0.22))
            .clipShape(RoundedRectangle(cornerRadius: configuration.iconSize * 0.22))

            if configuration.showsAppNames {
                Text(app.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .contentShape(Rectangle())
    }
}
