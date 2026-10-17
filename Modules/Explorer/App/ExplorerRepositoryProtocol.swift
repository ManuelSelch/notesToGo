import Foundation

/// Storage operations required by explorer use cases. Implementations live in Infra/.
protocol ExplorerRepositoryProtocol {
    func rootFolder() -> URL
    func loadDocuments(in folder: URL) throws -> [Document]
    func filenames(in folder: URL) throws -> [String]
    func ensureFolderExists(_ folder: URL) throws
    func createNote(at folder: URL, name: String) async throws -> Note
    func createFolder(at folder: URL, name: String) throws -> URL
}
