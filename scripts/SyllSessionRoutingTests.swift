import Foundation

@main
struct SyllSessionRoutingTests {
    static func main() {
        // The boundary the engine's stop path consults: a Remember observation
        // session must never route to ordinary delivery (paste/clipboard/
        // history), and cancellation must win over every use case.
        expect(.observation, for: .observation, cancelRequested: false)
        expect(.cancellation, for: .observation, cancelRequested: true)
        expect(.ordinaryDelivery, for: .newSession, cancelRequested: false)
        expect(.ordinaryDelivery, for: .assistantFollowUp, cancelRequested: false)
        expect(.command, for: .command, cancelRequested: false)
        expect(.cancellation, for: .newSession, cancelRequested: true)
        expect(.cancellation, for: .assistantFollowUp, cancelRequested: true)
        expect(.cancellation, for: .command, cancelRequested: true)
        print("Syll session routing tests passed")
    }

    private static func expect(
        _ expected: SyllSessionRouting.Outcome,
        for useCase: SyllSessionRouting.UseCase,
        cancelRequested: Bool
    ) {
        let actual = SyllSessionRouting.outcome(for: useCase, cancelRequested: cancelRequested)
        guard actual == expected else {
            fputs("FAIL\nuseCase: \(useCase)\ncancelRequested: \(cancelRequested)\nexpected: \(expected)\nactual: \(actual)\n", stderr)
            exit(1)
        }
    }
}
