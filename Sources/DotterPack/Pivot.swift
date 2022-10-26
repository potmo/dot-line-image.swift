import Foundation

struct Pivot: Equatable {
    let dotPoint: Point
    let pivotPoint: Point

    var x: Double {
        return dotPoint.x
    }

    var y: Double {
        return dotPoint.y - length
    }

    var length: Double {

        let l = dotPoint.y - pivotPoint.y

        //guard l >= 0 else { fatalError("pixel is upside down") }

        return l

    }

    init(pivotPoint: Point, dotPoint: Point) {
        self.dotPoint = dotPoint
        self.pivotPoint = pivotPoint
    }

    init(posA: Point, posB: Point) {
        self.dotPoint = posA
        self.pivotPoint = posB
    }

    init(_ labelA: LabeledBool, _ labelB: LabeledBool) {
        self.init(posA: Point(labelA.x, labelA.y), posB: Point(labelB.x, labelB.y))
    }
}
