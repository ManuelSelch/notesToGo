import Foundation

enum EditorError: Error, Equatable {
    case documentNotFound
    case missingFormatVersion
    case unsupportedFormatVersion(Int)
    case invalidNoteName
    case noteAlreadyExists
    case pdfWriteFailed
    case creationCleanupFailed(URL)
}
