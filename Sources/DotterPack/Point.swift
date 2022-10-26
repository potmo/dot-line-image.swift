import Foundation

struct Point: Equatable {
    let x: Double
    let y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y

        if x == Double.nan || y == Double.nan {
            fatalError("trying to set nan")
        }
    }

    init(_ x: Int, _ y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }

    init(_ x: Double, _ y: Int) {
        self.x = x
        self.y = Double(y)
    }

    init(_ x: Int, _ y: Double) {
        self.x = Double(x)
        self.y = y
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

    func normalized() -> Point {
        let length = self.length()
        if length == 0 {
            return Point(0,0)
        }
        return Point(x / length, y / length)
    }

    func length() -> Double {
        return sqrt(x * x + y * y)
    }

    func negated() -> Point {
        return Point(-x, -y)
    }

    func distanceTo(_ other: Point) -> Double {
        return sqrt(pow(other.x - self.x, 2) + pow(other.y - self.y, 2))
    }

    func distanceSquaredTo(_ other: Point) -> Double {
        return pow(other.x - self.x, 2) + pow(other.y - self.y, 2)
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
        let point = CGPoint(x: x, y: y)

        if point.x.isNaN || point.y.isNaN {
            fatalError("point ends up NaN")
        }
        return point
    }
}
