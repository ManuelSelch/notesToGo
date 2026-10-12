#if DEBUG
import Foundation

/// Test-runner paths are never accepted: all storage stays inside the app sandbox.
struct UITestStorage {
    let root: URL?
    let isCleanup: Bool

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        temporaryDirectory: URL = FileManager.default.temporaryDirectory
    ) throws {
        isCleanup = environment["NOTESTOGO_UI_TEST_MODE"] == "cleanup"
        guard let rawID = environment["NOTESTOGO_UI_TEST_ID"] else {
            guard !isCleanup else { throw ConfigurationError.invalidID }
            root = nil
            return
        }
        guard let id = UUID(uuidString: rawID) else { throw ConfigurationError.invalidID }
        root = temporaryDirectory.appendingPathComponent("NotesToGoUITests", isDirectory: true)
            .appendingPathComponent(id.uuidString, isDirectory: true)
    }

    func prepare() throws {
        guard let root else { return }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func cleanup() throws {
        guard let root, FileManager.default.fileExists(atPath: root.path) else { return }
        try FileManager.default.removeItem(at: root)
    }

    enum ConfigurationError: Error { case invalidID }
}
#endif
