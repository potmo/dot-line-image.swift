import Foundation


class PairwiseSequenceFinder {

    private var found: [Pivot] = []
    private var strayPixelsA: [LabeledBool] = []
    private var strayPixelsB: [LabeledBool] = []

    func getDiagonalsWithoutDirectHits(startDiagonalsA: [[LabeledBool]], startDiagonalsB: [[LabeledBool]]) async -> ([[LabeledBool]], [[LabeledBool]]) {
        return zip(startDiagonalsA, startDiagonalsB)
            .map{ diagonalA, diagonalB in
                return zip(diagonalA, diagonalB).map{ (pixelA, pixelB) -> (LabeledBool, LabeledBool) in
                    if pixelA.alignsWith(pixelB) {
                        self.found.append(Pivot(pixelA, pixelB))
                        // return empty pixel
                        return (LabeledBool(x: pixelA.x, y: pixelA.y, value: false),
                                LabeledBool(x: pixelB.x, y: pixelB.y, value: false))
                    }
                    // return pixels as is
                    return (pixelA, pixelB)
                }.unzip()
            }.unzip()
    }

    func getPairwiseAlignments(diagonalsA: [[LabeledBool]], diagonalsB: [[LabeledBool]]) async -> [([LabeledBool?], [LabeledBool?])] {
        let aligner = PairwiseAlignment<LabeledBool>()

        return await zip(diagonalsA, diagonalsB)
            .asyncMap{ diagonalA, diagonalB in
                let alignment = await aligner.computePairwiseAlignment(s1: diagonalA, s2: diagonalB)
                return alignment
            }
    }

    func getNonMatchingAlignments(alignments: [([LabeledBool?], [LabeledBool?])]) async ->  [([LabeledBool?], [LabeledBool?])]{
        return alignments.map{ (alignment: ([LabeledBool?], [LabeledBool?])) -> ([LabeledBool?], [LabeledBool?]) in

            var (newAlignedA, newAlignedB) = alignment

            for i in newAlignedA.indices {
                guard let pixelA = newAlignedA[i], let pixelB = newAlignedB[i] else {
                    continue
                }

                if pixelA.alignsWith(pixelB) {
                    self.found.append(Pivot(pixelA, pixelB))

                    // remove the found one
                    newAlignedA[i] = nil
                    newAlignedB[i] = nil
                }
            }

            return (newAlignedA, newAlignedB)
        }
    }

    func getStrayPixels(startDiagonalsA: [[LabeledBool]], startDiagonalsB: [[LabeledBool]]) async -> ([LabeledBool], [LabeledBool]) {
        let pixelsA = startDiagonalsA.flatMap{$0}
        let blackPixelsA = pixelsA.filter{pixel in return pixel.value}
        let strayPixelsA = blackPixelsA.filter{ pixel in
            return !found.contains(where: { pivot in
                Int(pivot.dotPoint.x) == pixel.x && Int(pivot.dotPoint.y) == pixel.y
            })
        }

        let pixelsB = startDiagonalsB.flatMap{$0}
        let blackPixelsB = pixelsB.filter{pixel in return pixel.value}
        let strayPixelsB = blackPixelsB.filter{ pixel in
            return !found.contains(where: { pivot in
                Int(pivot.pivotPoint.x) == pixel.x && Int(pivot.pivotPoint.y) == pixel.y
            })
        }


        return (strayPixelsA, strayPixelsB)
    }


    func printMatrix<T>(_ matrix: [[T]], printer: (T)->String) {
        for row in matrix {
            printArray(row, printer: printer)
        }
    }

    func printArray<T>(_ array: [T], printer: (T) -> String) {
        print(array.map(printer).joined())
    }

    func toTrueFalseNil(_ val: Bool?, _ trueString: String, _ falseString: String, _ nilString: String) -> String {
        guard let val else {
            return nilString
        }
        return val ? trueString : falseString
    }

    func printAlignments(of alignments: [([LabeledBool?], [LabeledBool?])], diagonalsA: [[LabeledBool]], diagonalsB: [[LabeledBool]]) {
        stride(from: 0, to: alignments.count, by: 1).forEach{ i in
            let diagonalA = diagonalsA[i]
            let diagonalB = diagonalsB[i]
            let alignment = alignments[i]

            printArray(diagonalA){ $0.value ? "■" : "□"}
            printArray(diagonalB){ $0.value ? "■" : "□"}

            printArray(diagonalA){ "(\($0.x),\($0.y))"}
            printArray(diagonalB){ "(\($0.x),\($0.y))"}

            printArray(alignment.0){ toTrueFalseNil($0?.value, "■", "□", "-") }
            printArray(alignment.1){ toTrueFalseNil($0?.value, "■", "□", "-") }


            let alignmentStrings = zip(alignment.0, alignment.1).map{ tup in
                if let a1 = tup.0, let a2 = tup.1 {
                    return ("(\(a1.x),\(a1.y))", "(\(a2.x),\(a2.y))")
                } else if let a1 = tup.0 {
                    let s = "(\(a1.x),\(a1.y))"
                    return (s, Array(repeating: "-", count: s.count).joined())
                } else if let a2 = tup.1 {
                    let s = "(\(a2.x),\(a2.y))"
                    return (Array(repeating: "-", count: s.count).joined(), s)
                } else {
                    return ("-", "-")
                }
            }.unzip()

            print(alignmentStrings.0.joined())
            print(alignmentStrings.1.joined())

            print("/////////////////////////")

        }
    }
}
