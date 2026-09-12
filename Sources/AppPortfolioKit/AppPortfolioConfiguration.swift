import SwiftUI

public struct AppPortfolioConfiguration: Sendable {
    public var title: String?
    public var columns: Int
    public var iconSize: CGFloat
    public var spacing: CGFloat
    public var showsAppNames: Bool
    public var excludesCurrentApp: Bool
    public var allowedDeveloperID: Int?

    public init(
        title: String? = "More apps",
        columns: Int = 3,
        iconSize: CGFloat = 72,
        spacing: CGFloat = 20,
        showsAppNames: Bool = true,
        excludesCurrentApp: Bool = true,
        allowedDeveloperID: Int? = nil
    ) {
        self.title = title
        self.columns = max(1, columns)
        self.iconSize = max(44, iconSize)
        self.spacing = max(0, spacing)
        self.showsAppNames = showsAppNames
        self.excludesCurrentApp = excludesCurrentApp
        self.allowedDeveloperID = allowedDeveloperID
    }

    public static let `default` = AppPortfolioConfiguration()
}
