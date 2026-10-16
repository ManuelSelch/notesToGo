import Foundation
import PDFKit
import PaperKit

/// PDFKit adapter, kept separate from explorer workflows and naming rules.
struct BlankPDFGenerator {
    static let creator = "NotesToGo.BlankTemplate"
    private let writePDF: (PDFDocument, URL) -> Bool

    init(writePDF: @escaping (PDFDocument, URL) -> Bool = { $0.write(to: $1) }) {
        self.writePDF = writePDF
    }

    func write(at url: URL, document: MultiPageDocument) throws {
        let pdf = PDFDocument()
        for (index, page) in document.pages.enumerated() {
            let pdfPage = PDFPage()
            pdfPage.setBounds(page.markup.bounds, for: .mediaBox)
            pdf.insert(pdfPage, at: index)
        }
        pdf.documentAttributes = [PDFDocumentAttribute.creatorAttribute: Self.creator]
        guard writePDF(pdf, url) else { throw EditorError.pdfWriteFailed }
    }
}
