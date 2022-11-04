import Foundation
import SwiftUI

class Solver {

    @ObservedObject private var state: ObservableState

    init(state: ObservableState) {

        self.state = state


        print("inputA")
        printMatrix(state.inputA.matrix) { $0.value ? "■" : "□"}

        print("inputB")
        printMatrix(state.inputB.matrix) { $0.value ? "■" : "□"}

        print("//////////")


        let addPivot = { (pixelA: LabeledBool, pixelB: LabeledBool) -> Void in
            DispatchQueue.main.async {
                self.addPivot(pixelA: pixelA, pixelB: pixelB)
            }
        }

        let addStrayPixelA = { (pixel: LabeledBool) -> Void in
            DispatchQueue.main.async {
                self.addStrayPixelA(pixel: pixel)
            }
        }

        let addStrayPixelB = { (pixel: LabeledBool) -> Void in
            DispatchQueue.main.async {
                self.addStrayPixelB(pixel: pixel)
            }
        }

        let setDependencies = { (dependencies: [Dependency]) -> Void in
            DispatchQueue.main.async {
                self.state.dependencies = dependencies
            }
        }


        let pairFinder = DiagonalPairFinder(diagonalsA: state.inputA.diagonals,
                                            diagonalsB: state.inputB.diagonals,
                                            pivotFoundCallback: addPivot,
                                            strayAFoundCallback: addStrayPixelA,
                                            strayBFoundCallback: addStrayPixelB,
                                            doneCallback: {self.findDependencies( setDependencies: setDependencies)})


        pairFinder.start()

    }

    func findDependencies(setDependencies: ([Dependency])-> Void) {
        let dependencyFinder = DependencyFinder()
        let dependencies = dependencyFinder.solve(pivots: state.foundPivots)

        setDependencies(dependencies)
    }

    func addPivot(pixelA: LabeledBool, pixelB: LabeledBool) {
        let pivot = Pivot(pixelA, pixelB)
        state.foundPixelsA.append(pixelA)
        state.foundPixelsB.append(pixelB)
        state.foundPivots.append(pivot)
    }

    func addStrayPixelA(pixel: LabeledBool) {
        state.strayPixelsA.append(pixel)
        state.strayPivotsA.append(Pivot(pixel, LabeledBool(x: pixel.x, y: -pixel.x, value: true)))
    }

    func addStrayPixelB(pixel: LabeledBool) {
        state.strayPixelsB.append(pixel)

        let pixelPoint = Point(pixel.x, pixel.y)

        let pivotPoint = Point(-pixelPoint.y,  pixelPoint.y)
        let dotPoint = Point(pivotPoint.x, pivotPoint.y + pixelPoint.x + pixelPoint.y)

        state.strayPivotsB.append(Pivot(pivotPoint: pivotPoint, dotPoint: dotPoint))
    }

    func printMatrix<T>(_ matrix: [[T]], printer: (T)->String) {
        for y in 0 ..< matrix[0].count {
            var row = ""
            for x in 0 ..< matrix.count {
                let val = matrix[x][y]
                row += printer(val)
            }
            print(row)
        }
    }

    func printArray<T>(_ array: [T], printer: (T) -> String) {
        print(array.map(printer).joined())
    }

  
}
