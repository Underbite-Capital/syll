import Foundation

@main
enum SyllCommandContextTests {
    static func main() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("syll-repo-context-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let repository = root.appendingPathComponent("portable-open-source-repo", isDirectory: true)
        let nested = repository.appendingPathComponent("Sources/Feature", isDirectory: true)
        try FileManager.default.createDirectory(
            at: repository.appendingPathComponent(".git", isDirectory: true),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        let document = nested.appendingPathComponent("Command.swift")
        try Data().write(to: document)

        guard SyllCommandContext.nearestRepositoryRoot(from: document) == repository else {
            fatalError("did not resolve the nearest repository from the focused document")
        }
        guard SyllCommandContext.nearestRepositoryRoot(from: root) == nil else {
            fatalError("must fail closed outside a repository")
        }
        print("Syll command context tests passed")
    }
}
