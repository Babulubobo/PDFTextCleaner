import CleanerCore
import AppKit

func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T, line: UInt = #line) {
    precondition(actual == expected, "Line \(line): expected \(expected), got \(actual)")
}

struct TextCleanerTests {
    func testChineseParagraphs() {
        let result = TextCleaner.clean("  从 PDF 复制的\r\n文本。\r\n \r\n第二段\r\n保留。  ")
        XCTAssertEqual(result.text, "从 PDF 复制的文本。\n\n第二段保留。")
        XCTAssertEqual(result.mergedBreaks, 2)
    }

    func testEnglishWordsAndPunctuation() {
        XCTAssertEqual(TextCleaner.clean("Hello\nworld\n!\nA (\nsmall\n) example.").text,
                       "Hello world! A (small) example.")
    }

    func testListsAndContinuation() {
        XCTAssertEqual(TextCleaner.clean("购物清单\n• 牛奶\n  和面包\n• 鸡蛋\n\n步骤\n1. Open the\nfile\n2. Copy it").text,
                       "购物清单\n• 牛奶和面包\n• 鸡蛋\n\n步骤\n1. Open the file\n2. Copy it")
        XCTAssertEqual(TextCleaner.clean("版本\n1.2 supports\nthis.").text, "版本1.2 supports this.")
    }

    func testHyphenRepairIsOptIn() {
        XCTAssertEqual(TextCleaner.clean("inter-\nnational").text, "inter-national")
        let result = TextCleaner.clean("inter-\nnational", repairHyphens: true)
        XCTAssertEqual(result.text, "international")
        XCTAssertEqual(result.repairedWords, 1)
        XCTAssertEqual(TextCleaner.clean("state-\nof-the-art").text, "state-of-the-art")
        XCTAssertEqual(TextCleaner.clean("inter\u{00AD}\nnational").text, "international")
    }

    func testPreserveLinesAndEmptyInput() {
        XCTAssertEqual(TextCleaner.clean("a\nb\n\nc", mergeLines: false).text, "a\nb\n\nc")
        XCTAssertEqual(TextCleaner.clean("\n \t\r\n").text, "")
        XCTAssertEqual(TextCleaner.clean("").mergedBreaks, 0)
        XCTAssertEqual(TextCleaner.clean("甲\u{2028}乙\u{2029}丙").text, "甲乙\n\n丙")
    }

    func testLongText() {
        let result = TextCleaner.clean(Array(repeating: "一行文字", count: 10_000).joined(separator: "\n"))
        XCTAssertEqual(result.mergedBreaks, 9_999)
        XCTAssertEqual(result.text.count, 40_000)
    }
}

let checks = TextCleanerTests()
checks.testChineseParagraphs()
checks.testEnglishWordsAndPunctuation()
checks.testListsAndContinuation()
checks.testHyphenRepairIsOptIn()
checks.testPreserveLinesAndEmptyInput()
checks.testLongText()

@MainActor
func checkClipboard() {
    let board = NSPasteboard.withUniqueName()
    defer { board.releaseGlobally() }
    func put(_ text: String) {
        board.clearContents()
        precondition(board.setString(text, forType: .string))
    }
    put("existing\ncopy")
    let cleaner = ClipboardCleaner(pasteboard: board)
    precondition(cleaner.poll() == nil, "Do not alter the clipboard at launch")
    XCTAssertEqual(board.string(forType: .string), "existing\ncopy")

    let rich = NSPasteboardItem()
    let richData = Data("{\\rtf1 Original rich text}".utf8)
    rich.setString("中文的\n第一段。\n\nEnglish text\ncontinues here.\n\n• first\n• second", forType: .string)
    rich.setData(richData, forType: .rtf)
    board.clearContents()
    precondition(board.writeObjects([rich]))
    let change = cleaner.poll()
    XCTAssertEqual(change?.result.text, "中文的第一段。\n\nEnglish text continues here.\n\n• first\n• second")
    XCTAssertEqual(board.string(forType: .string), change?.result.text)
    precondition(cleaner.canRestore)
    precondition(cleaner.poll() == nil, "Never reprocess our own clipboard write")
    precondition(cleaner.restore())
    XCTAssertEqual(board.string(forType: .string), change?.source)
    XCTAssertEqual(board.data(forType: .rtf), richData)
    precondition(cleaner.poll() == nil, "Restored text must not immediately be cleaned again")

    put("another\ncopy")
    precondition(cleaner.poll() != nil)
    put("newer copy")
    precondition(!cleaner.restore(), "Undo must never replace a newer copy")
    precondition(cleaner.poll() == nil, "Single-line text stays untouched")
    XCTAssertEqual(board.string(forType: .string), "newer copy")

    put("manual\nresult")
    cleaner.ignoreCurrentChange()
    precondition(cleaner.poll() == nil, "Ignore manual copies and enabling the feature")

    for excludedType in [NSPasteboard.PasteboardType.fileURL, .png,
                         NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")] {
        let item = NSPasteboardItem()
        item.setString("do not\nchange", forType: .string)
        item.setData(Data("marker".utf8), forType: excludedType)
        board.clearContents()
        precondition(board.writeObjects([item]))
        precondition(cleaner.poll() == nil)
        XCTAssertEqual(board.string(forType: .string), "do not\nchange")
    }

    put("inter-\nnational")
    XCTAssertEqual(cleaner.poll(repairHyphens: true)?.result.text, "international")
    put("keep\nlines")
    precondition(cleaner.poll(mergeLines: false) == nil)
    put("\n \n")
    precondition(cleaner.poll() == nil, "Do not replace a clipboard with empty output")
}

await checkClipboard()
print("Passed: text rules, 10,000-line input, clipboard cleaning, self-write suppression, rich-text restore, newer-copy protection, and excluded clipboard types.")
