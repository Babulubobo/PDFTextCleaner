import AppKit
import SwiftUI
import CleanerCore

@main
@MainActor
struct PDFTextCleanerApp: App {
    @StateObject private var model: CleanerModel

    init() {
        // Start monitoring at launch, even before the menu bar panel is opened.
        let initialModel = CleanerModel()
        _model = StateObject(wrappedValue: initialModel)
    }

    var body: some Scene {
        MenuBarExtra(tr("app.name"), systemImage: "text.badge.checkmark") {
            CleanerView(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class CleanerModel: ObservableObject {
    @Published var source = "" { didSet { clean() } }
    @Published var output = "" { didSet { message = "" } }
    @Published var mergeLines = true { didSet { clean() } }
    @Published var repairHyphens = false { didSet { clean() } }
    @Published var autoClean: Bool {
        didSet {
            UserDefaults.standard.set(autoClean, forKey: "autoCleanClipboard")
            clipboard.ignoreCurrentChange()
            message = ""
        }
    }
    @Published var message = ""
    @Published var isError = false
    @Published var mergedBreaks = 0
    @Published var repairedWords = 0
    @Published var generatedOutput = ""
    @Published var showingExample = false
    @Published var canRestore = false

    private let clipboard = ClipboardCleaner()
    private var timer: Timer?

    init() {
        let defaults = UserDefaults.standard
        autoClean = defaults.object(forKey: "autoCleanClipboard") == nil
            ? true : defaults.bool(forKey: "autoCleanClipboard")
        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkClipboard() }
        }
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    deinit { timer?.invalidate() }

    private func checkClipboard() {
        if autoClean, let change = clipboard.poll(mergeLines: mergeLines, repairHyphens: repairHyphens) {
            showingExample = false
            source = change.source
            message = tr("status.autoCleaned")
            isError = false
        }
        let available = clipboard.canRestore
        if canRestore != available { canRestore = available }
    }

    var canCopy: Bool { !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    var manuallyEdited: Bool { output != generatedOutput }

    func clean() {
        let result = TextCleaner.clean(source, mergeLines: mergeLines, repairHyphens: repairHyphens)
        output = result.text
        generatedOutput = result.text
        mergedBreaks = result.mergedBreaks
        repairedWords = result.repairedWords
        message = ""
        isError = false
    }

    func paste() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else {
            message = tr("error.noText")
            isError = true
            return
        }
        showingExample = false
        source = text
    }

    func copy() {
        guard canCopy else { return }
        NSPasteboard.general.clearContents()
        let success = NSPasteboard.general.setString(output, forType: .string)
        clipboard.ignoreCurrentChange()
        canRestore = false
        message = tr(success ? "status.copied" : "error.copy")
        isError = !success
    }

    func restore() {
        let success = clipboard.restore()
        canRestore = clipboard.canRestore
        message = tr(success ? "status.restored" : "error.restore")
        isError = !success
    }

    func clear() {
        source = ""
        showingExample = false
    }

    func loadExample() {
        showingExample = true
        source = tr("example.text")
    }

    static func lineCount(_ text: String) -> Int {
        text.isEmpty ? 0 : text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline).count
    }
}

// Hallmark: Workbench · native macOS controls · side-by-side comparison · no decorative motion.
struct CleanerView: View {
    @ObservedObject var model: CleanerModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(tr("app.name")).font(.system(size: 20, weight: .semibold))
                    Text(tr("app.subtitle"))
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                Button(tr("action.quit")) { NSApplication.shared.terminate(nil) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help(tr("help.quit"))
            }

            HStack(spacing: 12) {
                Toggle(tr("option.autoClean"), isOn: $model.autoClean)
                    .toggleStyle(.switch)
                    .fixedSize()
                Spacer(minLength: 8)
                Button(tr("action.restore"), action: model.restore)
                    .buttonStyle(.borderless)
                    .disabled(!model.canRestore)
            }
            Text(tr(model.autoClean ? "hint.autoOn" : "hint.autoOff"))
                .font(.system(size: 12)).foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button(action: model.paste) {
                    Label(tr("action.paste"), systemImage: "doc.on.clipboard")
                }
                .controlSize(.large)
                Button(tr("action.example"), action: model.loadExample).buttonStyle(.borderless)
                Spacer()
                Button(tr("action.clear"), action: model.clear)
                    .buttonStyle(.borderless)
                    .disabled(model.source.isEmpty && model.output.isEmpty)
            }

            HStack(spacing: 12) {
                editor(title: tr("editor.before"), detail: tr(model.showingExample ? "editor.example" : "editor.original"),
                       text: Binding(get: { model.source }, set: { model.showingExample = false; model.source = $0 }),
                       placeholder: tr("placeholder.before"), isResult: false)
                editor(title: tr("editor.after"), detail: tr(model.manuallyEdited ? "editor.edited" : "editor.live"),
                       text: $model.output, placeholder: tr("placeholder.after"), isResult: true)
            }

            HStack(spacing: 24) {
                Toggle(tr("option.mergeLines"), isOn: $model.mergeLines)
                Toggle(tr("option.repairHyphens"), isOn: $model.repairHyphens)
                    .help(tr("help.repairHyphens"))
                Spacer(minLength: 0)
            }
            .toggleStyle(.checkbox)
            .font(.system(size: 13))

            Text(tr("hint.paragraphs"))
                .font(.system(size: 12)).foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if !model.message.isEmpty {
                        Text(model.message)
                            .foregroundStyle(model.isError ? Color.red : Color.primary)
                    } else if model.source.isEmpty {
                        Text(tr("status.empty"))
                    } else {
                        Text(tr("status.merged", model.mergedBreaks)
                             + (model.repairedWords > 0 ? tr("status.repaired", model.repairedWords) : ""))
                    }
                    Text(tr("hint.local"))
                        .font(.system(size: 11)).foregroundStyle(.secondary)
                }
                .font(.system(size: 12))
                .accessibilityElement(children: .combine)
                Spacer(minLength: 0)
                Button(action: model.copy) {
                    Label(tr("action.copy"), systemImage: "doc.on.doc")
                        .padding(.horizontal, 10)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!model.canCopy)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .help(tr("help.copy"))
            }
        }
        .padding(20)
        .frame(width: 740)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func editor(title: String, detail: String, text: Binding<String>,
                        placeholder: String, isResult: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title).font(.system(size: 14, weight: .semibold))
                Spacer()
                Text(detail).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(isResult ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            Divider()
            ZStack(alignment: .topLeading) {
                TextEditor(text: text)
                    .disableAutocorrection(true)
                    .font(.system(size: 14))
                    .lineSpacing(6)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .accessibilityLabel(title)
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 14).padding(.vertical, 13)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 250)
            .background(Color(nsColor: .textBackgroundColor))
            Divider()
            Text(tr("editor.stats", text.wrappedValue.count, CleanerModel.lineCount(text.wrappedValue)))
                .font(.system(size: 11).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12).padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5))
    }
}
