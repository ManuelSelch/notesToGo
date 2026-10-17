import Foundation

nonisolated struct Note: Identifiable, Hashable, Codable, Sendable {
    let pdf: URL
    let markup: URL

    var id: URL { markup.absoluteURL }
}
