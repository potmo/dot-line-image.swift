import Foundation




import Foundation

struct Delay: AnimationRig {

    private let duration: Double
    init(duration: Double) {
        self.duration = duration
    }

    func create(at time: Double) -> AnimationRunner {
        return Runner(startTime: time, endTime: time + duration)
    }

    private struct Runner: AnimationRunner {
        private let startTime: Double
        private let endTime: Double

        init(startTime: Double, endTime: Double) {
            self.startTime = startTime
            self.endTime = endTime
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            let t = ((time - startTime) / (endTime - startTime)).clamped(to: 0...1)

            if t >= 1 {
                return .finished(atTime: endTime)
            }else{
                return .running
            }
        }
    }
}
