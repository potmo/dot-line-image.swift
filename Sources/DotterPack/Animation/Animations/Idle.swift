
import Foundation

struct Idle: AnimationRig {
    func create(at time: Double) -> AnimationRunner {
        return Runner()
    }

    private struct Runner: AnimationRunner {
        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            return .finished(atTime: time)
        }
    }
}
