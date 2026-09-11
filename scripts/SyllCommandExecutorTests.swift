import Foundation

@main
enum SyllCommandExecutorTests {
    @MainActor
    static func main() async throws {
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("syll-command-executor-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }

        let portFile = temporary.appendingPathComponent("port")
        let listener = Process()
        listener.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        listener.arguments = [
            "-c",
            "import socket,time,pathlib; s=socket.socket(); s.bind(('127.0.0.1',0)); s.listen(); pathlib.Path(\(String(reflecting: portFile.path))).write_text(str(s.getsockname()[1])); time.sleep(30)",
        ]
        try listener.run()
        defer {
            if listener.isRunning { listener.terminate() }
        }

        var port: Int?
        for _ in 0..<50 {
            if let text = try? String(contentsOf: portFile, encoding: .utf8) {
                port = Int(text)
                break
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        guard let port, let syllPort = SyllPort(port) else {
            fatalError("test listener did not publish a valid port")
        }

        let executor = SyllCommandExecutor()
        let emptyContext = SyllCommandContext(applicationName: nil, repositoryRoot: nil)
        let inspection = await executor.execute(.inspectPort(syllPort), context: emptyContext)
        guard inspection.kind == .information, inspection.result.contains("PID \(listener.processIdentifier)") else {
            fatalError("port inspection did not report the disposable listener: \(inspection)")
        }

        let stopped = await executor.execute(.killPort(syllPort), context: emptyContext)
        guard stopped.kind == .success, stopped.result.contains("port \(port) is free") else {
            fatalError("kill-port did not truthfully verify the disposable listener stopped: \(stopped)")
        }
        listener.waitUntilExit()

        let repository = temporary.appendingPathComponent("repository", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try runGit(["init", "-b", "command-test"], in: repository)
        try "change".write(to: repository.appendingPathComponent("untracked.txt"), atomically: true, encoding: .utf8)
        let status = await executor.execute(
            .gitStatus,
            context: SyllCommandContext(applicationName: "Test", repositoryRoot: repository)
        )
        guard status.kind == .information,
            status.result.contains("command-test"),
            status.result.contains("1 untracked")
        else { fatalError("git status result was not truthful: \(status)") }

        let missingContext = await executor.execute(.gitStatus, context: emptyContext)
        guard missingContext.kind == .failure, missingContext.result.contains("nothing executed") else {
            fatalError("repository command did not fail closed without context")
        }

        print("Syll command executor tests passed")
    }

    private static func runGit(_ arguments: [String], in repository: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["-C", repository.path] + arguments
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { fatalError("git fixture setup failed") }
    }
}
