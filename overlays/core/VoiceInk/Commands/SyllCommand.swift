import Foundation

struct SyllPort: Equatable, Sendable {
    let value: UInt16

    init?(_ value: Int) {
        guard (1...65_535).contains(value) else { return nil }
        self.value = UInt16(value)
    }
}

enum SyllNavigationAlias: String, Equatable, Sendable {
    case iqsStaging = "iqs staging"

    var url: URL {
        switch self {
        case .iqsStaging:
            URL(string: "https://iqs-staging-staging.up.railway.app/")!
        }
    }
}

enum SyllCommand: Equatable, Sendable {
    case inspectPort(SyllPort)
    case killPort(SyllPort)
    case gitStatus
    case copyBranch
    case openLocalhost(SyllPort)
    case openAlias(SyllNavigationAlias)

    var canonicalDescription: String {
        switch self {
        case .inspectPort(let port):
            "inspect-port(port: \(port.value))"
        case .killPort(let port):
            "kill-port(port: \(port.value))"
        case .gitStatus:
            "git-status"
        case .copyBranch:
            "copy-branch"
        case .openLocalhost(let port):
            "open-localhost(port: \(port.value))"
        case .openAlias(let alias):
            "open-alias(name: \(alias.rawValue))"
        }
    }
}

enum SyllCommandInterpretation: Equatable, Sendable {
    case command(SyllCommand)
    case invalid(description: String, reason: String)
    case unmatched

    var displayDescription: String {
        switch self {
        case .command(let command):
            command.canonicalDescription
        case .invalid(let description, _):
            description
        case .unmatched:
            "No matching command"
        }
    }
}

struct SyllCommandOutcome: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case success
        case information
        case failure
    }

    let heard: String
    let interpreted: String
    let result: String
    let kind: Kind
}
