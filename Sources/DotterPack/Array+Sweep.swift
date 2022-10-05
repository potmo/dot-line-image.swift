import Foundation

extension Array {
    func sweep<Output, Intermediate>(_ initial: Intermediate, transformer: (Intermediate, Element)-> (Intermediate, Output)) -> (Intermediate,[Output]) {

        var transformedElements: [Output] = []
        transformedElements.reserveCapacity(self.capacity)
        var intermediate: Intermediate = initial
        for element in self {
            let output: Output
            (intermediate, output) = transformer(intermediate, element)
            transformedElements.append(output)
        }

        return (intermediate, transformedElements)
    }
}
