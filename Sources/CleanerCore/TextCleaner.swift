import Foundation

public struct CleaningResult {
    public let text: String
    public let mergedBreaks: Int
    public let repairedWords: Int
}

public enum TextCleaner {
    private static let listStart = try! NSRegularExpression(
        pattern: #"^(?:[-*+•●▪◦–—]\s+|[0-9]+[.)]\s+|[0-9]+、\s*|[（(][0-9]+[）)]\s*|[一二三四五六七八九十]+[、）]\s*)"#
    )
    private static let horizontalSpace = CharacterSet(charactersIn: " \t\u{00A0}")

    public static func clean(_ source: String, mergeLines: Bool = true,
                             repairHyphens: Bool = false) -> CleaningResult {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\u{2028}", with: "\n")
            .replacingOccurrences(of: "\u{2029}", with: "\n\n")
            .replacingOccurrences(of: "\u{000C}", with: "\n")
        var pieces: [String] = []
        var previous: String?
        var paragraphBreak = false
        var merged = 0
        var repaired = 0

        for rawLine in normalized.components(separatedBy: "\n") {
            let line = rawLine.trimmingCharacters(in: horizontalSpace)
            if line.isEmpty {
                if previous != nil { paragraphBreak = true }
                continue
            }
            let visible = line.replacingOccurrences(of: "\u{00AD}", with: "")
            if let previous {
                if paragraphBreak {
                    pieces.append("\n\n")
                } else if !mergeLines || isListStart(line) {
                    pieces.append("\n")
                } else {
                    merged += 1
                    if previous.hasSuffix("\u{00AD}") {
                        repaired += 1
                    } else if hasLatinHyphen(previous, next: line) {
                        if repairHyphens {
                            pieces[pieces.count - 1].removeLast()
                            repaired += 1
                        }
                    } else if needsSpace(previous, line) {
                        pieces.append(" ")
                    }
                }
            }
            pieces.append(visible)
            previous = line
            paragraphBreak = false
        }
        return CleaningResult(text: pieces.joined(), mergedBreaks: merged, repairedWords: repaired)
    }

    private static func isListStart(_ text: String) -> Bool {
        listStart.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    private static func hasLatinHyphen(_ previous: String, next: String) -> Bool {
        let tail = Array(previous.suffix(2).unicodeScalars)
        guard tail.count == 2, tail[1].value == 45, let first = next.unicodeScalars.first else { return false }
        return ((65...90).contains(tail[0].value) || (97...122).contains(tail[0].value))
            && (97...122).contains(first.value)
    }

    private static func needsSpace(_ previous: String, _ next: String) -> Bool {
        guard let last = previous.last, let first = next.first else { return false }
        if "（([【《“‘".contains(last) || "，。！？；：、,.!?;:）)]】》”’%".contains(first) { return false }
        return !isCJK(last) && !isCJK(first)
    }

    private static func isCJK(_ character: Character) -> Bool {
        character.unicodeScalars.contains {
            (0x2E80...0x9FFF).contains($0.value) || (0xF900...0xFAFF).contains($0.value)
            || (0x20000...0x323AF).contains($0.value) || (0xAC00...0xD7AF).contains($0.value)
        }
    }
}
