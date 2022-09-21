
import Foundation
extension Array {
    func unzip<T1, T2>() -> ([T1], [T2]) where Element == (T1, T2) {
        var result = ([T1](), [T2]())

        result.0.reserveCapacity(self.count)
        result.1.reserveCapacity(self.count)

        return reduce(into: result) { acc, pair in
            acc.0.append(pair.0)
            acc.1.append(pair.1)
        }
    }
}
