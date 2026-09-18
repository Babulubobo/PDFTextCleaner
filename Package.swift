// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PDFTextCleaner",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "PDFTextCleaner", targets: ["PDFTextCleaner"])],
    targets: [
        .target(name: "CleanerCore"),
        .executableTarget(name: "PDFTextCleaner", dependencies: ["CleanerCore"]),
        .executableTarget(name: "CleanerChecks", dependencies: ["CleanerCore"], path: "Tests/CleanerChecks")
    ]
)
