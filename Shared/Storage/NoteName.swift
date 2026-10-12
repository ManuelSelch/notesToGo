import Foundation

/// Shared base-name validation for creation and future rename operations.
enum NoteName {
    static func validated(_ value: String) throws -> String {
        let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let forbidden = CharacterSet.controlCharacters.union(CharacterSet(charactersIn: "/\\:"))
        guard !name.isEmpty,
              name != ".", name != "..",
              !name.hasPrefix("."),
              name.rangeOfCharacter(from: forbidden) == nil else {
            throw EditorError.invalidNoteName
        }
        return name
    }
}
