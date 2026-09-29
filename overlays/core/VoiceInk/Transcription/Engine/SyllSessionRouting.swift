import Foundation

/// Session routing boundary for a stopped recording. The engine's stop path
/// must consult this single function so that a Remember observation session
/// can never fall through into ordinary delivery (paste/clipboard/history),
/// and a cancellation always wins over every use case.
enum SyllSessionRouting {
    enum UseCase: Equatable, Sendable {
        case newSession
        case assistantFollowUp
        case command
        case observation
    }

    enum Outcome: Equatable, Sendable {
        /// Ordinary dictation delivery (transcription history + paste path).
        case ordinaryDelivery
        case command
        /// Remember observation capture: durable store only, never delivery.
        case observation
        case cancellation
    }

    static func outcome(for useCase: UseCase, cancelRequested: Bool) -> Outcome {
        if cancelRequested { return .cancellation }
        switch useCase {
        case .newSession, .assistantFollowUp:
            return .ordinaryDelivery
        case .command:
            return .command
        case .observation:
            return .observation
        }
    }
}
