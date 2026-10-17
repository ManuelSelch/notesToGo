import Foundation
import Testing

@testable import notesToGo

extension ExplorerModuleTests {
    struct ExplorerDomainTests {
        @Test
        func foldersComeFirstAndNamesUseNaturalOrder() {
            let folder2 = Document.folder(URL(fileURLWithPath: "/Folder 2"))
            let folder10 = Document.folder(URL(fileURLWithPath: "/Folder 10"))
            let note2 = note("note 2")
            let note10 = note("Note 10")
            let alpha = note("Alpha")

            #expect(DocumentOrdering().sorted([note10, folder10, note2, alpha, folder2])
                == [folder2, folder10, alpha, note2, note10])
        }

        @Test
        func equalDisplayNamesHaveDeterministicOrdering() {
            let first = note("Note")
            let second = note("note")
            let ordering = DocumentOrdering()

            #expect(ordering.sorted([first, second]) == ordering.sorted([second, first]))
            #expect(ordering.sorted([]).isEmpty)
        }

        @Test
        func noteNamesReserveBothFilesIgnoringCaseAndUseFirstFreeSuffix() {
            let naming = DocumentNaming()
            let filenames = ["Report.PDF", ".report 2.MARKUP", "Report 4.pdf"]

            #expect(naming.noteNameExists("report", filenames: filenames))
            #expect(naming.uniqueNoteName(base: "Report", filenames: filenames) == "Report 3")
            #expect(naming.uniqueNoteName(base: "New", filenames: filenames) == "New")
            #expect(!naming.noteNameExists("Report 3", filenames: filenames))
        }

        @Test
        func folderNamesReserveExistingEntriesIncludingFiles() {
            #expect(DocumentNaming().uniqueFolderName(base: "Work", filenames: ["Work", "Work 2", "Other.pdf"]) == "Work 3")
        }

        @Test
        func quickNoteBaseNameUsesSuppliedCalendarAndDate() {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let naming = DocumentNaming()
            let date = Date(timeIntervalSince1970: 1_700_000_000)

            #expect(naming.quickNoteBaseName(date: date, calendar: calendar) == "2023-11-14")
        }

        private func note(_ name: String) -> Document {
            .note(Note(pdf: URL(fileURLWithPath: "/\(name).pdf"), markup: URL(fileURLWithPath: "/.\(name).markup")))
        }
    }
}
