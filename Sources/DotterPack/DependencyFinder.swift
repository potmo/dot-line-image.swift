import Foundation

struct DependencyFinder {

    func solve(pivots: [Pivot]) -> [Dependency] {

        let nodes: [TempDependency] = pivots.enumerated().map{ (index, pivot) in
            return TempDependency(pivot: pivot, index: index)
        }

        for node in nodes {
            findParents(for: node, in: nodes)
        }


        let roots = nodes.filter(\.parents.isEmpty)

        roots.forEach{ root in root.depth = 0}

        var queue = nodes

        while !queue.isEmpty {
            let node = queue.remove(at: 0)
            node.setDepthToMaxParentPlusOne()


            // depth could not be calculated so try again later
            if node.depth == nil {
                queue.append(node)
            }
        }

        let maxDepth = nodes.compactMap(\.depth).max() ?? 0

        for i in 0...maxDepth {
            let nodesAtDepth = nodes.filter{$0.depth == i}
            print("\(i): " + nodesAtDepth.map{_ in "X"}.joined(separator: " "))
        }

        for node in nodes {
            // fix appearent children
            node.children = node.children.filter{node.depth! + 1 == $0.depth!}
            node.parents = node.parents.filter{node.depth! - 1 == $0.depth!}
        }

        var dependencies: [Int: Dependency] = [:]
        for root in nodes.filter({$0.parents.isEmpty}) {
            dependencies = createDependency(node: root, previous: dependencies)
        }


        return Array(dependencies.values)
    }

    func createDependency(node: TempDependency, previous: [Int: Dependency]) -> [Int: Dependency] {

        if previous.keys.contains(node.id) {
            return previous
        }

        var current = previous

        for child in node.children {
            current = createDependency(node: child, previous: current)
        }

        if node.children.isEmpty {
            current[node.id] = .leaf(depth: node.depth!, pivot: node.pivot)
        }

        let childNodes = node.children.map(\.id).map{ current[$0]! }

        if node.parents.isEmpty {
            current[node.id] = .root(depth: node.depth!, pivot: node.pivot, children: childNodes)
        }else{
            current[node.id] = .branch(depth: node.depth!, pivot: node.pivot, children: childNodes)
        }

        return current

    }

    func findParents(for node: TempDependency, in nodes: [TempDependency]) {
        // if a pivot arm swings over another pivots pivot point it will have to be on top so all within that circle section is considered children
        // roots does not have a parent

        for otherNode in nodes where otherNode != node {

            // other pivots need to be in the upper left quadrant for them to be able to swing over the pivot
            guard otherNode.point.x <= node.point.x && otherNode.point.y <= node.point.y else {
                continue
            }

            let distanceSquared = node.point.distanceSquaredTo(otherNode.point)

            if distanceSquared <= otherNode.lengthSquared {
                node.parents.append(otherNode)
                otherNode.children.append(node)
            }
        }
    }


}



class TempDependency: Equatable, Hashable, CustomStringConvertible {
    let pivot: Pivot
    var parents: [TempDependency]
    var children: [TempDependency]
    let point: Point
    let lengthSquared: Double
    let id: Int
    var depth: Int?

    init(pivot: Pivot, index: Int) {
        self.pivot = pivot
        self.parents = []
        self.children = []
        self.point = pivot.pivotPoint
        self.lengthSquared = pivot.length * pivot.length
        self.id = index
    }

    static func == (lhs: TempDependency, rhs: TempDependency) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func setDepthToMaxParentPlusOne() {

        if self.depth != nil {
            return
        }

        // if not all parents has a depth we can't set ours
        guard parents.allSatisfy({ $0.depth != nil}) else {
            return
        }

        let parentMaxDepth = parents.map{ parent in
            guard let parentDepth = parent.depth else {
                fatalError("the parent has no depth yet")
            }

            return parentDepth
        }.max()

        guard let parentMaxDepth else {
            fatalError("I dont have no depth")
        }

        self.depth = parentMaxDepth + 1

    }

    var description: String {
        let parentString = parents.map(\.id).map(String.init).joined(separator: ", ")
        let childrenString = children.map(\.id).map(String.init).joined(separator: ", ")
        let depth = self.depth == nil ? "-" : String(self.depth!)
        return "\(id) (\(depth)) parents (\(parents.count)): \(parentString) children (\(children.count)): \(childrenString)"
    }
}

enum Dependency {
    case root(depth: Int, pivot: Pivot, children: [Dependency])
    case branch(depth: Int, pivot: Pivot, children: [Dependency])
    case leaf(depth: Int, pivot: Pivot)
}
