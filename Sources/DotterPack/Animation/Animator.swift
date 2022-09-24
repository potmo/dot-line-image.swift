import Foundation
import simd


class ThingUsingAnimations {
    init() {
        let animator = Animator()

        animator.enqueueSequence{
            LinearTranslation(duration: 10, from: [1,2,3], to: [0,0,0])
            LinearTranslation(duration: 20, from: [1,1,1], to: [2,2,2])

            LinearTranslation(duration: 10, from: { [1,1,1] }, to: { [1,2,3] })
            Delay(duration: 10)

            InParallel{
                LinearTranslation(duration: 10, from: [0,0,0], to: [1,1,1])
                LinearRotation(duration: 10, from: { simd_quatf() }, to: { simd_quatf() })

                InSequence{
                    LinearTranslation(duration: 10, from: [1,2,3], to: [1,2,3])
                    LinearRotation(duration: 10, from: { simd_quatf() }, to: { simd_quatf() })
                    LinearTranslation(duration: 10, from: [1,2,3], to: [1,2,3])
                }
            }

            if true {
                LinearTranslation(duration: 10, from: [1,2,3], to: [1,2,3])
            }

            While{
                return true
            }

            Call{
                print("All done")
            }
        }

        let animatable = TestAnimatable()
        animator.tick(time: Date().timeIntervalSince1970, with: animatable)

    }
}

class TestAnimatable: Animatable {
    var position: SIMD3<Float> = SIMD3.zero
    var orientation: simd_quatf = simd_quatf()
}

class Animator {

    //TODO: Check out these easing functions
    // https://github.com/danro/jquery-easing/blob/master/jquery.easing.js

    private var queue: [AnimationRig]
    private var currentAnimation: AnimationRunner

    init() {
        self.queue = []
        self.currentAnimation = Idle().create(at: Date().timeIntervalSince1970)
    }

    func enqueue(_ animation: AnimationRig) {
        queue.insert(animation, at: queue.startIndex)
    }

    func enqueueSequence(@AnimationArrayBuilder _ builder: () -> [AnimationRig]) {
        let rigs = builder()
        queue.insert( InSequence(rigs: rigs), at: queue.startIndex)
    }

    func enqueueInParallel(@AnimationArrayBuilder _ builder: () -> [AnimationRig]) {
        let rigs = builder()
        queue.insert( InParallel(rigs: rigs), at: queue.startIndex)
    }

    func tick(time: Double, with thing: Animatable) {

        while true {
            let state = currentAnimation.apply(to: thing, with: time)

            switch state {
                case .running:
                    return
                case .finished(let finishTime):
                    guard let newAnimation = queue.popLast() else {
                        self.currentAnimation = Idle().create(at: finishTime)
                        return
                    }

                    self.currentAnimation = newAnimation.create(at: finishTime)
            }
        }
    }
}

protocol AnimationRig {
    func create(at time: Double) -> AnimationRunner
}


protocol AnimationRunner {
    func apply(to thing: Animatable, with time: Double) -> AnimationResult
}

enum AnimationResult {
    case running
    case finished(atTime: Double)
}

protocol Animatable: AnyObject {
    var position: SIMD3<Float> {get set}
    var orientation: simd_quatf {get set}
}

