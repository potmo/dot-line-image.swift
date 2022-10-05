import Foundation

extension String {
    func leftPad(toLength length: Int, with padding: Character = " ") -> String {
        let paddingChars = length - self.count

        if paddingChars <= 0 {
            return self
        }

        return String(repeating: padding, count: paddingChars) + self
    }
}
