import Foundation

/// Equatable, sendable error information suitable for feature state and user-facing retry UI.
nonisolated struct OperationFailure: Equatable, Sendable {
    let message: String

    init(_ error: Error) {
        if let error = error as? EditorError {
            switch error {
            case .documentNotFound:
                message = "The PDF file is missing. Restore it and try again."
            case .invalidPDF:
                message = "The PDF file is damaged or empty. Restore a valid PDF and try again."
            case .corruptDocument:
                message = "The editable note data is damaged. Restore it from a backup and try again. Your files have not been changed."
            case .missingFormatVersion:
                message = "This note has no format version. Older formats are not supported. Your files have not been changed."
            case let .unsupportedFormatVersion(version):
                message = "Note format version \(version) is not supported by this app. Your files have not been changed."
            case .invalidNoteName:
                message = "Enter a valid name without path separators, control characters, or a leading dot."
            case .noteAlreadyExists:
                message = "A note with this name already exists. Choose another name and try again."
            case .pdfWriteFailed:
                message = "The PDF could not be created. Check available storage and try again."
            case let .creationCleanupFailed(folder):
                message = "Creation failed and temporary files could not be removed. They were retained in \(folder.lastPathComponent). Check storage access before trying again."
            }
        } else {
            let error = error as NSError
            if error.domain == NSCocoaErrorDomain,
               error.code == CocoaError.fileReadNoPermission.rawValue || error.code == CocoaError.fileWriteNoPermission.rawValue {
                message = "Storage access was denied. Check file permissions and try again."
            } else {
                message = "\(error.localizedDescription) Check the file location and available storage, then try again."
            }
        }
    }
}
