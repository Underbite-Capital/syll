import AppKit
import Darwin
import Foundation

@MainActor
final class SyllCommandExecutor {
    func execute(_ command: SyllCommand, context: SyllCommandContext) async -> SyllCommandOutcome.KindAndResult {
        switch command {
        case .inspectPort(let port):
            return await inspectPort(port)
        case .killPort(let port):
            return await killPort(port)
        case .gitStatus:
            return await gitStatus(context: context)
        case .copyBranch:
            return await copyBranch(context: context)
        case .openLocalhost(let port):
            var components = URLComponents()
            components.scheme = "http"
            components.host = "localhost"
            components.port = Int(port.value)
            guard let url = components.url else {
                return .failure("Could not construct the localhost URL; nothing executed")
            }
            return open(url)
        case .openAlias(let alias):
            return open(alias.url)
        }
    }

    private func inspectPort(_ port: SyllPort) async -> SyllCommandOutcome.KindAndResult {
        switch await listeners(on: port) {
        case .failure(let message):
            return .failure(message.message)
        case .success(let listeners):
            guard !listeners.isEmpty else {
                return .information("Nothing is listening on port \(port.value)")
            }
            let summary = listeners.map { "\($0.command) (PID \($0.pid))" }.joined(separator: ", ")
            return .information("\(summary) is listening on port \(port.value)")
        }
    }

    private func killPort(_ port: SyllPort) async -> SyllCommandOutcome.KindAndResult {
        let initial: [PortListener]
        switch await listeners(on: port) {
        case .failure(let message):
            return .failure(message.message)
        case .success(let listeners):
            initial = listeners
        }

        guard !initial.isEmpty else {
            return .failure("Nothing is listening on port \(port.value); nothing executed")
        }

        let unique = Dictionary(grouping: initial, by: \.pid).compactMap(\.value.first)
        guard unique.count == 1, let listener = unique.first else {
            return .failure("Multiple processes own port \(port.value); nothing was stopped")
        }
        guard listener.userID == getuid() else {
            return .failure("The listener is owned by another user; nothing was stopped")
        }
        guard listener.pid != getpid() else {
            return .failure("Syll will not stop itself; nothing was stopped")
        }
        guard Darwin.kill(listener.pid, SIGTERM) == 0 else {
            return .failure("Could not send SIGTERM to \(listener.command) (PID \(listener.pid)); nothing was stopped")
        }

        for _ in 0..<10 {
            try? await Task.sleep(for: .milliseconds(200))
            switch await listeners(on: port) {
            case .failure(let message):
                return .failure("SIGTERM was sent to PID \(listener.pid), but verification failed: \(message)")
            case .success(let remaining):
                if !remaining.contains(where: { $0.pid == listener.pid }) {
                    if remaining.isEmpty {
                        return .success("Stopped \(listener.command) (PID \(listener.pid)); port \(port.value) is free")
                    }
                    let replacement = remaining.map { "\($0.command) (PID \($0.pid))" }.joined(separator: ", ")
                    return .information(
                        "Stopped \(listener.command) (PID \(listener.pid)); \(replacement) now occupies port \(port.value)"
                    )
                }
            }
        }

        return .failure("SIGTERM was sent to PID \(listener.pid), but port \(port.value) is still occupied")
    }

    private func gitStatus(context: SyllCommandContext) async -> SyllCommandOutcome.KindAndResult {
        guard let repository = context.repositoryRoot else {
            return .failure("Could not determine the active repository; nothing executed")
        }
        let result = await BoundedProcess.run(
            executable: URL(fileURLWithPath: "/usr/bin/git"),
            arguments: ["-C", repository.path, "status", "--short", "--branch"]
        )
        guard !result.timedOut else { return .failure("Git status timed out") }
        guard result.status == 0 else { return .failure(result.failureSummary(prefix: "Git status failed")) }

        let lines = result.stdout.split(whereSeparator: \.isNewline).map(String.init)
        let branch = lines.first.map(branchSummary) ?? repository.lastPathComponent
        var modified = 0
        var untracked = 0
        for line in lines.dropFirst() {
            if line.hasPrefix("??") { untracked += 1 } else { modified += 1 }
        }
        return .information("\(branch) · \(modified) modified · \(untracked) untracked")
    }

    private func copyBranch(context: SyllCommandContext) async -> SyllCommandOutcome.KindAndResult {
        guard let repository = context.repositoryRoot else {
            return .failure("Could not determine the active repository; clipboard unchanged")
        }
        let result = await BoundedProcess.run(
            executable: URL(fileURLWithPath: "/usr/bin/git"),
            arguments: ["-C", repository.path, "branch", "--show-current"]
        )
        guard !result.timedOut else { return .failure("Reading the branch timed out; clipboard unchanged") }
        guard result.status == 0 else { return .failure(result.failureSummary(prefix: "Reading the branch failed")) }

        let branch = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !branch.isEmpty else { return .failure("Repository is at detached HEAD; clipboard unchanged") }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        guard pasteboard.setString(branch, forType: .string),
            pasteboard.string(forType: .string) == branch
        else { return .failure("Could not verify the clipboard write") }
        return .success("Copied branch \(branch)")
    }

    private func open(_ url: URL) -> SyllCommandOutcome.KindAndResult {
        if NSWorkspace.shared.open(url) {
            return .success("macOS accepted the open request for \(url.absoluteString)")
        }
        return .failure("macOS rejected the open request; nothing opened")
    }

    private func listeners(on port: SyllPort) async -> Result<[PortListener], PortInspectionError> {
        let result = await BoundedProcess.run(
            executable: URL(fileURLWithPath: "/usr/sbin/lsof"),
            arguments: ["-nP", "-a", "-iTCP:\(port.value)", "-sTCP:LISTEN", "-Fpcu"]
        )
        if result.timedOut { return .failure(PortInspectionError("Inspecting port \(port.value) timed out")) }
        if result.status == 1 && result.stdout.isEmpty { return .success([]) }
        guard result.status == 0 else {
            return .failure(PortInspectionError(result.failureSummary(prefix: "Port inspection failed")))
        }
        return .success(PortListener.parse(result.stdout))
    }

    private func branchSummary(_ statusHeader: String) -> String {
        statusHeader
            .replacingOccurrences(of: "## ", with: "")
            .components(separatedBy: "...")
            .first
            ?? statusHeader
    }
}

extension SyllCommandOutcome {
    struct KindAndResult: Equatable, Sendable {
        let kind: Kind
        let result: String

        static func success(_ result: String) -> KindAndResult { KindAndResult(kind: .success, result: result) }
        static func information(_ result: String) -> KindAndResult { KindAndResult(kind: .information, result: result) }
        static func failure(_ result: String) -> KindAndResult { KindAndResult(kind: .failure, result: result) }
    }
}

private struct PortListener: Equatable {
    let pid: pid_t
    let command: String
    let userID: uid_t

    static func parse(_ output: String) -> [PortListener] {
        var listeners: [PortListener] = []
        var pid: pid_t?
        var command: String?
        var userID: uid_t?

        func appendCurrent() {
            if let pid, let command, let userID {
                listeners.append(PortListener(pid: pid, command: command, userID: userID))
            }
        }

        for line in output.split(whereSeparator: \.isNewline).map(String.init) {
            switch line.first {
            case "p":
                appendCurrent()
                pid = Int32(String(line.dropFirst()))
                command = nil
                userID = nil
            case "c":
                command = String(line.dropFirst())
            case "u":
                userID = UInt32(String(line.dropFirst()))
            default:
                break
            }
        }
        appendCurrent()
        return listeners
    }
}

private struct PortInspectionError: Error, CustomStringConvertible {
    let message: String
    var description: String { message }

    init(_ message: String) {
        self.message = message
    }
}

private struct BoundedProcessResult: Sendable {
    let status: Int32
    let stdout: String
    let stderr: String
    let timedOut: Bool

    func failureSummary(prefix: String) -> String {
        let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        return detail.isEmpty ? "\(prefix) with status \(status)" : "\(prefix): \(detail.prefix(300))"
    }
}

private enum BoundedProcess {
    private static let outputLimit = 65_536
    private static let timeout: TimeInterval = 3

    static func run(executable: URL, arguments: [String]) async -> BoundedProcessResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = executable
                process.arguments = arguments
                process.environment = [
                    "HOME": NSHomeDirectory(),
                    "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
                    "LANG": "en_US.UTF-8",
                ]

                let temporaryDirectory = FileManager.default.temporaryDirectory
                    .appendingPathComponent("syll-command-\(UUID().uuidString)", isDirectory: true)
                let outputURL = temporaryDirectory.appendingPathComponent("stdout")
                let errorURL = temporaryDirectory.appendingPathComponent("stderr")

                do {
                    try FileManager.default.createDirectory(
                        at: temporaryDirectory,
                        withIntermediateDirectories: true
                    )
                    FileManager.default.createFile(atPath: outputURL.path, contents: nil)
                    FileManager.default.createFile(atPath: errorURL.path, contents: nil)
                    let outputHandle = try FileHandle(forWritingTo: outputURL)
                    let errorHandle = try FileHandle(forWritingTo: errorURL)
                    process.standardOutput = outputHandle
                    process.standardError = errorHandle

                    try process.run()
                    outputHandle.closeFile()
                    errorHandle.closeFile()
                } catch {
                    try? FileManager.default.removeItem(at: temporaryDirectory)
                    continuation.resume(returning: BoundedProcessResult(
                        status: -1, stdout: "", stderr: error.localizedDescription, timedOut: false))
                    return
                }

                let deadline = Date().addingTimeInterval(timeout)
                while process.isRunning && Date() < deadline {
                    Thread.sleep(forTimeInterval: 0.02)
                }
                let timedOut = process.isRunning
                if timedOut {
                    process.terminate()
                    let terminationDeadline = Date().addingTimeInterval(0.5)
                    while process.isRunning && Date() < terminationDeadline {
                        Thread.sleep(forTimeInterval: 0.02)
                    }
                    if process.isRunning { Darwin.kill(process.processIdentifier, SIGKILL) }
                }
                process.waitUntilExit()

                let stdout = (try? Data(contentsOf: outputURL, options: .mappedIfSafe).prefix(outputLimit)) ?? Data()
                let stderr = (try? Data(contentsOf: errorURL, options: .mappedIfSafe).prefix(outputLimit)) ?? Data()
                try? FileManager.default.removeItem(at: temporaryDirectory)
                continuation.resume(returning: BoundedProcessResult(
                    status: process.terminationStatus,
                    stdout: String(data: stdout, encoding: .utf8) ?? "",
                    stderr: String(data: stderr, encoding: .utf8) ?? "",
                    timedOut: timedOut
                ))
            }
        }
    }
}
