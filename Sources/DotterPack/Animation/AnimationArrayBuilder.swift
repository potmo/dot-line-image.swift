import Foundation


@resultBuilder
struct AnimationArrayBuilder {
    typealias Component = [AnimationRig]
    typealias Expression = AnimationRig
    typealias Result = [AnimationRig]

    static func buildExpression(_ element: Expression) -> Component {
        return [element]
    }
    static func buildExpression() -> Component {
        return []
    }
    static func buildOptional(_ component: Component?) -> Component {
        guard let component = component else { return [] }
        return component
    }
    static func buildEither(first component: Component) -> Component {
        return component
    }
    static func buildEither(second component: Component) -> Component {
        return component
    }
    static func buildArray(_ components: [Component]) -> Component {
        return Array(components.joined())
    }
    static func buildBlock(_ components: Component...) -> Component {
        return Array(components.joined())
    }
    func buildFinalResult(_ component: Component) -> Result {
        return component
    }
}
