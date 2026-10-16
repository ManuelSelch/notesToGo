import Foundation

/// Explorer presentation policy, independent of storage and view state.
nonisolated struct DocumentOrdering {
    func sorted(_ documents: [Document]) -> [Document] {
        documents.sorted { lhs, rhs in
            if lhs.isFolder != rhs.isFolder { return lhs.isFolder }
            let comparison = lhs.displayName.localizedStandardCompare(rhs.displayName)
            if comparison != .orderedSame { return comparison == .orderedAscending }
            // Natural comparison can consider distinct names equal (case, leading zeros).
            // Use the actual URL as a stable tie-breaker, never directory enumeration order.
            return lhs.url.absoluteString < rhs.url.absoluteString
        }
    }
}

private extension Document {
    var isFolder: Bool {
        if case .folder = self { return true }
        return false
    }

    var url: URL {
        switch self {
        case .note(let note): return note.pdf
        case .folder(let folder): return folder
        }
    }

    var displayName: String {
        switch self {
        case .note: return url.deletingPathExtension().lastPathComponent
        case .folder: return url.lastPathComponent
        }
    }
}
