import Foundation

extension Double {
    func string(_ fractionDigits: Int, length: Int = 0) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"

    }
}
