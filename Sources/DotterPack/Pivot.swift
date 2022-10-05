import Foundation

struct Pivot {
    let dotPoint: Point
    let posB: Point

    var x: Double {
        return dotPoint.x
    }

    var y: Double {
        return dotPoint.y - length
    }

    var length: Double {

        let l = dotPoint.y - posB.y

        //guard l >= 0 else { fatalError("pixel is upside down") }

        return l

    }

    init(pivotPoint: Point, dotPoint: Point) {
        self.dotPoint = dotPoint
        self.posB = pivotPoint
    }

    init(posA: Point, posB: Point) {
        self.dotPoint = posA
        self.posB = posB
    }

    init(_ labelA: LabeledBool, _ labelB: LabeledBool) {
        self.init(posA: Point(labelA.x, labelA.y), posB: Point(labelB.x, labelB.y))
    }
}
