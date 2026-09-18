import Foundation

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources")
let languages = ["en", "zh-Hans", "zh-Hant"]
var tables: [String: [String: String]] = [:]
for language in languages {
    let path = root.appendingPathComponent("\(language).lproj/Localizable.strings")
    let data = try Data(contentsOf: path)
    guard let table = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
        fatalError("Invalid localization: \(language)")
    }
    tables[language] = table
}
let english = tables["en"]!
for language in languages {
    let table = tables[language]!
    precondition(Set(table.keys) == Set(english.keys), "Missing or extra keys: \(language)")
    for (key, value) in table {
        precondition(!value.isEmpty, "Empty translation: \(language)/\(key)")
        precondition(value.components(separatedBy: "%ld").count == english[key]!.components(separatedBy: "%ld").count,
                     "Format mismatch: \(language)/\(key)")
    }
    let localeBundle = Bundle(path: root.appendingPathComponent("\(language).lproj").path)!
    precondition(localeBundle.localizedString(forKey: "app.name", value: nil, table: nil) == table["app.name"])
}
for (preference, expected) in [("en-US", "en"), ("zh-CN", "zh-Hans"), ("zh-TW", "zh-Hant")] {
    precondition(Bundle.preferredLocalizations(from: languages, forPreferences: [preference]).first == expected)
}
print("Passed: English, Simplified Chinese, Traditional Chinese, format arguments, and system language matching.")
