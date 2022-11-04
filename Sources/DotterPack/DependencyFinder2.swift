import Foundation

struct DependencyFinder2 {

    func solve(pivots: [Pivot]) -> [Dependency] {

        // convert to dependency nodes
        var dependencies = pivots.enumerated().map{ (index, pivot) in
            return DependencyNode(index: index, pivotPoint: pivot.pivotPoint, pendulumPoint: pivot.dotPoint)
        }

        // merge dependencies that has the same pivot point since they can hang on the same thread
        var merged: [Point: DependencyNode] = [:]
        for node in dependencies {

            guard let previousNode = merged[node.pivotPoint] else {
                merged[node.pivotPoint] = node
                continue
            }

            previousNode.pendulumPoints.formUnion(node.pendulumPoints)
        }
        dependencies = Array(merged.values)


        /// children is within the swing of the parent
        // a parents children is only the direct children

        // the parent ends up s´closest to the camera and the leaf nodes furthest away
        //FIXME: Find the nodes within the swing
        //FIXME: when a child is found within the swing the current node either takes over the parenthood or not
        



        return []
    }
}

func setChildren(for node: DependencyNode, among nodes: [DependencyNode]) {

}

class DependencyNode: Equatable {

    let index: Int
    let pivotPoint: Point
    var pendulumPoints: Set<Point>

    var longestPendulumLength: Double {
        return pendulumLengths.max()!
    }

    var pendulumLengths: [Double] {
        return pendulumPoints.map { $0.y - pivotPoint.y }
    }

    var parent: DependencyNode?
    var children: [DependencyNode]

    init(index: Int, pivotPoint: Point, pendulumPoint: Point) {
        self.pivotPoint = pivotPoint
        self.pendulumPoints = [pendulumPoint]
        self.parent = nil
        self.children = []
        self.index = index
    }

    static func == (lhs: DependencyNode, rhs: DependencyNode) -> Bool {
        return lhs.index == rhs.index
    }

}

