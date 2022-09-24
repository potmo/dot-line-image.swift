
import Foundation

struct While: AnimationRig {

    private let evaluator: () -> Bool

    init(_ isDoneEvaluator: @escaping () -> Bool) {
        self.evaluator = isDoneEvaluator
    }

    func create(at time: Double) -> AnimationRunner {
        return Runner(callback: evaluator)
    }

    private struct Runner: AnimationRunner {
        private let evaluator: () -> Bool

        init(callback: @escaping () -> Bool ) {
            self.evaluator = callback
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            if self.evaluator() {
                return .finished(atTime: time)
            }else {
                return .running
            }

        }
    }
}
