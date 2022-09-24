import Foundation

struct Pivot {
    let posA: Point
    let posB: Point

    var x: Double {
        return posA.x
    }

    var y: Double {
        if posA.x < posB.x {
            return posB.y
        }else{
            return posB.y - length * 2
        }
    }

    var length: Double {
        if posA.x < posB.x {
            return posA.y - posB.y
        } else {
            return posB.y - posA.y
        }

    }

    init(posA: Point, posB: Point) {
        self.posA = posA
        self.posB = posB
    }

    init(_ labelA: LabeledBool, _ labelB: LabeledBool) {
        self.init(posA: Point(labelA.x, labelA.y), posB: Point(labelB.x, labelB.y))
    }
}
