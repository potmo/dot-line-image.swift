import Foundation

struct InParallel: AnimationRig {

    let rigs: [AnimationRig]
    init(rigs: [AnimationRig]) {
        self.rigs = rigs
    }

    init(@AnimationArrayBuilder builder: () -> [AnimationRig]) {
        self.rigs = builder()
    }

    func create(at time: Double) -> AnimationRunner {
        let runners = rigs.map{ rig in
            rig.create(at: time)
        }

        return Runner(runners: runners)
    }


    private struct Runner: AnimationRunner {

        private let runners: [AnimationRunner]

        init(runners: [AnimationRunner]) {
            self.runners = runners
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {

            let results = runners.map{ runner in
                return runner.apply(to: thing, with: time)
            }

            var latestFinish = time
            for result in results {
                switch result {
                    case .running:
                        return .running
                    case .finished(let finishTime):
                        latestFinish = max(latestFinish, finishTime)
                }
            }

            return .finished(atTime: latestFinish)

        }
    }

}
