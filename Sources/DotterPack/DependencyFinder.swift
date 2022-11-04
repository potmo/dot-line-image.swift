import Foundation

struct DependencyFinder {

    func solve(pivots: [Pivot]) -> [Dependency] {

        let nodes: [TempDependency] = pivots.enumerated().map{ (index, pivot) in
            return TempDependency(pivot: pivot, index: index)
        }

        for node in nodes {
            findParents(for: node, in: nodes)
        }


        var roots = nodes.filter(\.parents.isEmpty)

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
        roots = nodes.filter(\.parents.isEmpty)
        for (rootId, root) in roots.enumerated() {
            createDependency(node: root, dependencies: &dependencies, rootId: rootId, depth: 0)
        }

        return dependencies.values.map({$0})
    }

    func createDependency(node: TempDependency, dependencies: inout [Int: Dependency], rootId: Int, depth: Int) {

        if dependencies.keys.contains(node.id) {
            return
        }

        for child in node.children {
            createDependency(node: child, dependencies: &dependencies, rootId: rootId, depth: depth + 1)
        }

        if node.children.isEmpty {
            dependencies[node.id] = .leaf(depth: depth, pivot: node.pivot, rootId: rootId)
        }

        let childNodes = node.children.map(\.id).map{ dependencies[$0]! }

        if node.parents.isEmpty {
            dependencies[node.id] = .root(depth: depth, pivot: node.pivot, children: childNodes, rootId: rootId)
        }else{
            dependencies[node.id] = .branch(depth: depth, pivot: node.pivot, children: childNodes, rootId: rootId)
        }

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
                node.children.append(otherNode)
                otherNode.parents.append(node)
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
    case root(depth: Int, pivot: Pivot, children: [Dependency], rootId: Int)
    case branch(depth: Int, pivot: Pivot, children: [Dependency], rootId: Int)
    case leaf(depth: Int, pivot: Pivot, rootId: Int)

    var isRoot: Bool {
        switch self {
            case .root: return true
            default: return false
        }
    }

    var isLeaf: Bool {
        switch self {
            case .leaf: return true
            default: return false
        }
    }

    var isBranch:  Bool {
        switch self {
            case .branch: return true
            default: return false
        }
    }

    var children: [Dependency] {
        switch self {
            case .root(_, _, let children, _):
                return children
            case .branch(_, _, let children, _):
                return children
            case .leaf(_, _, _):
                return []
        }
    }

    var allChildren: [Dependency] {
        switch self {
            case .root(_, _, let children, _):
                return children.flatMap(\.allChildren)
            case .branch(_, _, let children, _):
                return children.flatMap(\.allChildren)
            case .leaf(_, _, _):
                return []
        }
    }

    var pivot: Pivot {
        switch self {
            case .root(_, let pivot, _, _):
                return pivot
            case .branch(_, let pivot, _, _):
                return pivot
            case .leaf(_, let pivot, _):
                return pivot
        }
    }

    var depth: Int {
        switch self {
            case .root(let depth, _, _, _):
                return depth
            case .branch(let depth, _, _, _):
                return depth
            case .leaf(let depth, _, _):
                return depth
        }
    }

    var rootId: Int {
        switch self {
            case .root(_,_,_, let rootId):
                return rootId
            case .branch(_,_,_, let rootId):
                return rootId
            case .leaf(_,_, let rootId):
                return rootId
        }
    }


}
