#if DEBUG
import Foundation
import PDFKit

/// Debug-only real-file fixtures requested explicitly by error-flow UI tests.
/// Normal launches and Release builds never create these files.
enum UITestFixtures {
    static func prepare() throws {
        let environment = ProcessInfo.processInfo.environment
        guard try UITestStorage().root != nil,
              let requestedName = environment["NOTESTOGO_UI_TEST_NOTE"],
              requestedName.hasPrefix("AT Error "),
              let format = environment["NOTESTOGO_UI_TEST_MARKUP"],
              ["corrupt", "unsupported"].contains(format) else { return }
        let name = try NoteName.validated(requestedName)
        let folder = Explorer().rootFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let pdfURL = folder.appendingPathComponent("\(name).pdf")
        let markupURL = folder.appendingPathComponent(".\(name).markup")
        guard !FileManager.default.fileExists(atPath: pdfURL.path),
              !FileManager.default.fileExists(atPath: markupURL.path) else { return }
        let pdf = PDFDocument()
        pdf.insert(PDFPage(), at: 0)
        guard pdf.write(to: pdfURL) else { throw EditorError.pdfWriteFailed }
        let content = format == "corrupt" ? "Damaged editable note data" : "{\"formatVersion\":999}"
        try Data(content.utf8).write(to: markupURL, options: .atomic)
    }
}
#endif
