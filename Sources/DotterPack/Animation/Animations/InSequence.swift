import Foundation

import Foundation

struct InSequence: AnimationRig {

    let rigs: [AnimationRig]
    init(rigs: [AnimationRig]) {
        self.rigs = rigs
    }

    init(@AnimationArrayBuilder builder: () -> [AnimationRig]) {
        self.rigs = builder()
    }

    func create(at time: Double) -> AnimationRunner {
        return Runner(rigs: rigs, at: time)
    }


    private class Runner: AnimationRunner {

        private var runner: AnimationRunner
        private var pendingRigs: [AnimationRig]

        init(rigs: [AnimationRig], at time: Double) {

            self.pendingRigs = rigs
            guard let rig = self.pendingRigs.popLast() else {
                self.runner = Idle().create(at: time)
                return
            }

            self.runner = rig.create(at: time)
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {

            let result = runner.apply(to: thing, with: time)

            switch result {
                case .running:
                    return .running
                case .finished(let finishTime):
                    guard let nextRig = pendingRigs.popLast() else {
                        return .finished(atTime: finishTime)
                    }

                    self.runner = nextRig.create(at: finishTime)
                    return .running
            }

        }
    }

}

