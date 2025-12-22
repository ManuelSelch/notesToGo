import Foundation

struct DocumentItem: Identifiable {
    let id = UUID()
    let name: String
    let editableURL: URL
    let exportedPDFURL: URL?
    let modifiedDate: Date
}
