import Foundation
import SwiftUI

class Solver {

    @Binding var showDots: Bool
    @Binding var showConnections: Bool
    @Binding var showPoints: Bool
    @Binding var showStrings: Bool
    @Binding var showStrays: Bool

    @Binding var inputA: PixelImage<LabeledBool>
    @Binding var inputB: PixelImage<LabeledBool>
    @Binding var foundPivots: [Pivot]
    @Binding var foundPixelsA: [LabeledBool]
    @Binding var foundPixelsB: [LabeledBool]
    @Binding var strayPixelsA: [LabeledBool]
    @Binding var strayPixelsB: [LabeledBool]
    @Binding var strayPivotsA: [Pivot]
    @Binding var strayPivotsB: [Pivot]


    init(showDots: Binding<Bool>,
         showConnections: Binding<Bool>,
         showPoints: Binding<Bool>,
         showStrings: Binding<Bool>,
         showStrays: Binding<Bool>,
         inputA: Binding<PixelImage<LabeledBool>>,
         inputB: Binding<PixelImage<LabeledBool>>,
         foundPivots: [Binding<Pivot]>,
         foundPixelsA: [Binding<LabeledBool]>,
         foundPixelsB: [Binding<LabeledBool]>,
         strayPixelsA: [Binding<LabeledBool]>,
         strayPixelsB: [Binding<LabeledBool]>,
         strayPivotsA: [Binding<Pivot]>,
         strayPivotsB: [Binding<Pivot]>) {

        self._inputA = inputA
        self._inputB = inputB
        self._foundPivots = foundPivots
        self._foundPixelsA = foundPixelsA
        self._foundPixelsB = foundPixelsB
        self._strayPixelsA = strayPixelsA
        self._strayPixelsB = strayPixelsB
        self._strayPivotsA = strayPivotsA
        self._strayPivotsB = strayPivotsB

        self._showDots = showDots
        self._showConnections = showConnections
        self._showPoints = showPoints
        self._showStrings = showStrings
        self._showStrays = showStrays


        self.foundPivots = []
        self.strayPivotsA = []
        self.strayPivotsB = []

        self.foundPixelsA = []
        self.foundPixelsB = []
        self.strayPixelsA = []
        self.strayPixelsB = []

        var generator = RandomNumberGeneratorWithSeed(seed: 23232)
        let size = 30

        //Bool.random(using: &generator)

        self.inputA = PixelImage<LabeledBool>(width: size, height: size, pixels: stride(from: 0, to: size, by: 1).map{ y in
            return stride(from: 0, to: size, by: 1).map{ x in
                return LabeledBool(x: x, y: y, value: (y + x).isMultiple(of: 2))
            }
        }.flatMap{$0})

        self.inputB = PixelImage<LabeledBool>(width: size, height: size, pixels: stride(from: 0, to: size, by: 1).map{ y in
            return stride(from: 0, to: size, by: 1).map{ x in
                return LabeledBool(x: x, y: y, value: (y + x).isMultiple(of: 2))
            }
        }.flatMap{$0})

        self.inputA = loadImage(name: "happy1").pixelImage().floydSteinbergDithered().monochromed().labeled()
        self.inputB = loadImage(name: "happy2").pixelImage().floydSteinbergDithered().monochromed().rotatedCCW().labeled()


        print("inputA")
        printMatrix(self.inputA.matrix) { $0.value ? "■" : "□"}

        print("inputB")
        printMatrix(self.inputB.matrix) { $0.value ? "■" : "□"}

        print("//////////")



        let pairFinder = DiagonalPairFinder(diagonalsA: self.inputA.diagonals,
                                            diagonalsB: self.inputB.diagonals,
                                            pivotFoundCallback: self.addPivot,
                                            strayAFoundCallback: self.addStrayPixelA,
                                            strayBFoundCallback: self.addStrayPixelB,
                                            doneCallback: self.findDependencies)


        pairFinder.start()

    }

    func findDependencies() {
        let dependencyFinder = DependencyFinder()
        let dependencies = dependencyFinder.solve(pivots: self.foundPivots)

        for dependency in dependencies {
            switch dependency {
                case .root:
                    print(dependency)
                case .branch:
                    continue
                case .leaf:
                    continue
            }
        }
    }

    func addPivot(pixelA: LabeledBool, pixelB: LabeledBool) {
        let pivot = Pivot(pixelA, pixelB)
        self.foundPixelsA.append(pixelA)
        self.foundPixelsB.append(pixelB)
        self.foundPivots.append(pivot)
    }

    func addStrayPixelA(pixel: LabeledBool) {
        self.strayPixelsA.append(pixel)
        self.strayPivotsA.append(Pivot(pixel, LabeledBool(x: pixel.x, y: -pixel.x, value: true)))
    }

    func addStrayPixelB(pixel: LabeledBool) {
        self.strayPixelsB.append(pixel)

        let pixelPoint = Point(pixel.x, pixel.y)

        let pivotPoint = Point(-pixelPoint.y,  pixelPoint.y)
        let dotPoint = Point(pivotPoint.x, pivotPoint.y + pixelPoint.x + pixelPoint.y)

        self.strayPivotsB.append(Pivot(pivotPoint: pivotPoint, dotPoint: dotPoint))
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

    func loadImage(name: String) -> NSImage {
        guard let path = Bundle.module.path(forResource: name, ofType: "png"), let image = NSImage(contentsOfFile: path) else {
            fatalError("Couldnt load image \(name).png")
        }
        return image
    }
}
