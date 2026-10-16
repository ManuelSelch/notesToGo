import Foundation

/// Naming decisions operate on a snapshot of filenames, without accessing disk.
nonisolated struct DocumentNaming {
    func noteNameExists(_ name: String, filenames: [String]) -> Bool {
        filenames.contains {
            $0.caseInsensitiveCompare("\(name).pdf") == .orderedSame
                || $0.caseInsensitiveCompare(".\(name).markup") == .orderedSame
        }
    }

    func uniqueNoteName(base: String, filenames: [String]) -> String {
        uniqueName(base: base) { noteNameExists($0, filenames: filenames) }
    }

    func uniqueFolderName(base: String, filenames: [String]) -> String {
        uniqueName(base: base) { candidate in
            filenames.contains { $0.caseInsensitiveCompare(candidate) == .orderedSame }
        }
    }

    func quickNoteBaseName(date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func uniqueName(base: String, exists: (String) -> Bool) -> String {
        var candidate = base
        var index = 2
        while exists(candidate) {
            candidate = "\(base) \(index)"
            index += 1
        }
        return candidate
    }
}
