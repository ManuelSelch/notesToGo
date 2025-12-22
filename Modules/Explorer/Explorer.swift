import Foundation

/// load & save documents & folders
class Explorer {
    func loadAllDocuments() -> [DocumentItem] {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let editableDir = docs.appendingPathComponent("editable")
        let exportsDir = docs.appendingPathComponent("exports")

        var items: [DocumentItem] = []

        guard let files = try? fm.contentsOfDirectory(at: editableDir, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return []
        }

        for file in files where file.pathExtension == "markup" {
            let name = file.deletingPathExtension().lastPathComponent
            let exportedPDF = exportsDir.appendingPathComponent(name + ".pdf")
            let date = (try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date()
            
            let item = DocumentItem(
                name: name,
                editableURL: file,
                exportedPDFURL: fm.fileExists(atPath: exportedPDF.path) ? exportedPDF : nil,
                modifiedDate: date
            )
            items.append(item)
        }

        return items.sorted { $0.modifiedDate > $1.modifiedDate } // newest first
    }
}
