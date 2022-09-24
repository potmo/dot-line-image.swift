
import Foundation

struct Call: AnimationRig {

    private let callback: () -> Void

    init(_ callback: @escaping () -> Void) {
        self.callback = callback
    }
    func create(at time: Double) -> AnimationRunner {
        return Runner(callback: callback)
    }

    private struct Runner: AnimationRunner {
        private let callback: () -> Void

        init(callback: @escaping () -> Void ) {
            self.callback = callback
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            self.callback()
            return .finished(atTime: time)
        }
    }
}
