import Foundation

import Foundation
import simd
import RealityKit

struct LinearRotation: AnimationRig {

    private let duration: Double
    private let startOrientationProvider: () -> simd_quatf
    private let endOrientationProvider: () -> simd_quatf

    init(duration: Double,
         from evaluatedStartOrientation: @escaping () -> simd_quatf,
         to evaluatedEndOrientation: @escaping () -> simd_quatf) {
        self.duration = duration
        self.startOrientationProvider = evaluatedStartOrientation
        self.endOrientationProvider = evaluatedEndOrientation
    }

    init(duration: Double,
         from startOrientatin: simd_quatf,
         to endOrientation: simd_quatf) {
        self.init(duration: duration, from: {return startOrientatin}, to: {return endOrientation})
    }


    func create(at time: Double) -> AnimationRunner {
        return Runner(startTime: time,
                      endTime: time + duration,
                      startOrientation: startOrientationProvider(),
                      endOrientation: endOrientationProvider())
    }

    private struct Runner: AnimationRunner {
        private let startTime: Double
        private let endTime: Double
        private let startOrientation: simd_quatf
        private let endOrientation: simd_quatf

        init(startTime: Double, endTime: Double, startOrientation: simd_quatf, endOrientation: simd_quatf) {
            self.startTime = startTime
            self.endTime = endTime
            self.startOrientation = startOrientation
            self.endOrientation = endOrientation
        }

        func apply(to thing: Animatable, with time: Double) -> AnimationResult {
            let t = ((time - startTime) / (endTime - startTime)).clamped(to: 0...1)
            let orientation = simd_slerp(startOrientation, endOrientation, Float(t))
            thing.orientation = orientation

            if t >= 1 {
                return .finished(atTime: endTime)
            }else{
                return .running
            }
        }
    }
}


