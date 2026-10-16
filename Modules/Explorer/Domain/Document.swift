import Foundation

nonisolated enum Document: Identifiable, Hashable, Sendable {
    case note(Note)
    case folder(URL)

    var id: Self { self }
}
