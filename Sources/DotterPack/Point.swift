import Foundation

struct Point {
    let x: Double
    let y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    init(_ x: Int, _ y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }

    func rotated(around pivot: Point, by radians: Double) -> Point{
        let point = self
        //var radians = (Math.PI / 180) * angle,
        let cos = cos(radians)
        let sin = sin(radians)
        let nx = (cos * (point.x - pivot.x)) + (sin * (point.y - pivot.y)) + pivot.x
        let ny = (cos * (point.y - pivot.y)) - (sin * (point.x - pivot.x)) + pivot.y
        return Point(nx, ny)
    }

    static func +(lhs: Point, rhs: Point) -> Point {
        return Point(lhs.x + rhs.x, lhs.y + rhs.y)
    }

    static func -(lhs: Point, rhs: Point) -> Point {
        return Point(lhs.x - rhs.x, lhs.y - rhs.y)
    }

    static func *(lhs: Point, rhs: Double) -> Point {
        return Point(lhs.x * rhs, lhs.y * rhs)
    }

    static func *(lhs: Double, rhs: Point) -> Point {
        return Point(lhs * rhs.x, lhs * rhs.y)
    }

    static func *(lhs: Point, rhs: Int) -> Point {
        return Point(lhs.x * Double(rhs), lhs.y * Double(rhs))
    }

    static func *(lhs: Int, rhs: Point) -> Point {
        return Point(Double(lhs) * rhs.x, Double(lhs) * rhs.y)
    }

    static func /(lhs: Point, rhs: Double) -> Point {
        return Point(lhs.x / rhs, lhs.y / rhs)
    }


    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
}
