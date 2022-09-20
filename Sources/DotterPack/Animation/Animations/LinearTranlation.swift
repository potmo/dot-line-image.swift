import Foundation

import Foundation
import simd
import RealityKit

struct LinearTransition: AnimationRig {

    private let duration: Double
    private let startPositionProvider: () -> SIMD3<Float>
    private let endPositionProvider: () -> SIMD3<Float>

    init(duration: Double,
         from evaluatedStartPosition: @escaping () -> SIMD3<Float>,
         to evaluatedEndPosition: @escaping () -> SIMD3<Float>) {
        self.duration = duration
        self.startPositionProvider = evaluatedStartPosition
        self.endPositionProvider = evaluatedEndPosition
    }

    init(duration: Double,
         from startPosition: SIMD3<Float>,
         to endPosition: SIMD3<Float>) {
        self.init(duration: duration, from: {return startPosition}, to: {return endPosition})
    }


    func create(at time: Double) -> AnimationRunner {
        return Runner(startTime: time,
                      endTime: time + duration,
                      startPosition: startPositionProvider(),
                      endPosition: endPositionProvider())
    }

    private struct Runner: AnimationRunner {
        private let startTime: Double
        private let endTime: Double
        private let startPosition: SIMD3<Float>
        private let endPosition: SIMD3<Float>

        init(startTime: Double, endTime: Double, startPosition: SIMD3<Float>, endPosition: SIMD3<Float>) {
            self.startTime = startTime
            self.endTime = endTime
            self.startPosition = startPosition
            self.endPosition = endPosition
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            let t = ((time - startTime) / (endTime - startTime)).clamped(to: 0...1)
            let position = simd_mix(startPosition, endPosition, [Float(t),Float(t),Float(t)])

            thing.position = position

            if t >= 1 {
                return .finished(atTime: endTime)
            }else{
                return .running
            }
        }
    }
}


