//
//  File.swift
//  
//
//  Created by Nisse Bergman on 2022-09-28.
//

import Foundation

class DiagonalPairFinder {

    private var pivotFoundCallback: (Pivot) -> Void
    private var strayAFoundCallback: (LabeledBool) -> Void
    private var strayBFoundCallback: (LabeledBool) -> Void

    private let diagonalsA: [[LabeledBool]]
    private let diagonalsB: [[LabeledBool]]

    init(diagonalsA: [[LabeledBool]],
         diagonalsB: [[LabeledBool]],
         pivotFoundCallback: @escaping (Pivot) -> Void,
         strayAFoundCallback: @escaping (LabeledBool) -> Void,
         strayBFoundCallback: @escaping (LabeledBool) -> Void) {
        self.diagonalsA = diagonalsA
        self.diagonalsB = diagonalsB
        self.pivotFoundCallback = pivotFoundCallback
        self.strayAFoundCallback = strayAFoundCallback
        self.strayBFoundCallback = strayBFoundCallback

    }



    func start() {
        Task {
            computeDiagonalPairs(diagonalsA: diagonalsA, diagonalsB: diagonalsB)
        }
    }

    private func computeDiagonalPairs(diagonalsA: [[LabeledBool]], diagonalsB: [[LabeledBool]]) {

        zip(diagonalsA, diagonalsB).forEach(computeDiagonalPairs2)
    }

    private func computeDiagonalPairs(labelsA: [LabeledBool], labelsB: [LabeledBool]) {


        print("A: \(labelsA.string)")
        print("B: \(labelsB.string)")

        let blackPixelsA = labelsA.filter(\.value)
        let blackPixelsB = labelsB.filter(\.value)

        // early exist if both are empty
        if blackPixelsA.isEmpty && blackPixelsB.isEmpty {
            return
        }

        // only  pixelBs to the right of pixelA
        let pixelBCandidates = labelsA.enumerated().filter(\.element.value).map{ indexA, pixel in
            return labelsB[indexA...].filter(\.value)
        }

        var takenInB: [LabeledBool] = []

        pixelBCandidates.enumerated().forEach{index, candidates in
            let pixelA = blackPixelsA[index]

            let nonTakenCandiates = candidates.filter{!takenInB.contains($0)}

            //print("\(index): (\(pixelA.x), \(pixelA.y))")
            //print("candidates: \(nonTakenCandiates.map{"(\($0.x), \($0.y))"}.joined(separator: ", "))")


            // check if any candidates that are not taken
            if nonTakenCandiates.isEmpty {
                //print("A stray: (\(pixelA.x), \(pixelA.y))")
                strayAFoundCallback(pixelA)
                return
            }

            let pixelB = nonTakenCandiates.first!
            // take the last candidate
            let pivot = Pivot(pixelA, pixelB)
            //print("connect with (\(pixelB.x), \(pixelB.y))")
            pivotFoundCallback(pivot)
            takenInB.append(pixelB)
        }

        blackPixelsB.filter{ !takenInB.contains($0) }.forEach{ pixelB in
            //print("B stray: (\(pixelB.x), \(pixelB.y))")
            self.strayBFoundCallback(pixelB)
        }

        //print("------")

    }


    private func computeDiagonalPairs2(labelsA: [LabeledBool], labelsB: [LabeledBool]) {


        let bestOffset = findBestPullForceOffset(between: labelsA, and: labelsB)

        var a = self.pad(array: labelsA, by: bestOffset)
        var b = labelsB

        print("a:  " + labelsA.string)
        print("b:  " + labelsB.string)
        print("a': " + a.string)

        print("/-/-/-/-/-/-/-/-/")


        for lookDistance in 0 ..< b.count {
            for aIndex in 0 ..< a.count {

                let bIndex = aIndex + lookDistance
                if bIndex >= b.count {
                    continue
                }

                let aPixel = a[aIndex]
                let bPixel = b[bIndex]

                if aPixel.value && bPixel.value {

                    let pivot = Pivot(aPixel, bPixel)
                    pivotFoundCallback(pivot)

                    // take it
                    a[aIndex] = LabeledBool(x: aPixel.x, y: aPixel.y, value: false)
                    b[bIndex] = LabeledBool(x: bPixel.x, y: bPixel.y, value: false)
                }
            }
        }

        a.filter(\.value).forEach(self.strayAFoundCallback)
        b.filter(\.value).forEach(self.strayBFoundCallback)
    }

    func findBestPullForceOffset(between labelsA: [LabeledBool], and labelsB: [LabeledBool]) -> Int {
        let best = stride(from: 0, to: labelsB.count, by: 1)
            .map{ i in
                let score = calulateOffsetScore(offsetedBy: i, labelsA: labelsA, labelsB: labelsB)
                return (score: score, offset: i)
            }
            .sorted(by: {$0.score < $1.score})
            .first

        guard let best else {
            fatalError("there must be one that is best")
        }

        return best.offset
    }

    func pad(array: [LabeledBool], by offset: Int) -> [LabeledBool] {
        return Array(repeating: LabeledBool(x: 0, y: 0, value: false), count: offset) + array
    }

    func calulateOffsetScore(offsetedBy offset: Int, labelsA: [LabeledBool], labelsB: [LabeledBool]) -> Double {

        let a = pad(array: labelsA, by: offset)
        let b = labelsB

        let distances = a.enumerated().filter(\.element.value).map{ indexA, pixel in

            if indexA >= b.count {
                return 0.0
            }

            // get the pixelBs to the right of pixelA and figure out the sum of distances from A to all Bs
            let totalPixelDistance = b.enumerated()
                .filter(\.element.value)
                .map(\.offset)
                .filter{$0 >= indexA}
                .map{ indexB in
                    return pow(Double(indexB - indexA), 2)
                }
                .reduce(0, +)

            return totalPixelDistance
        }

        let lastBlackBIndex = b.enumerated().filter(\.element.value).last?.offset ?? a.startIndex
        let unreachableA = Double(a.enumerated().filter{$0.offset > lastBlackBIndex}.filter(\.element.value).count)
        let reachableA = Double(a.enumerated().filter{$0.offset <= lastBlackBIndex}.filter(\.element.value).count)

        let firstBlackA = a.enumerated().filter(\.element.value).first?.offset ?? b.endIndex
        let unreachableB = Double(b.enumerated().filter{$0.offset < firstBlackA}.filter(\.element.value).count)
        let reachableB = Double(b.enumerated().filter{$0.offset >= firstBlackA}.filter(\.element.value).count)

        let unreachablePenalty = (unreachableA + unreachableB) * Double(a.count) + Double(a.count - b.count) * 4
        let totalDistance = distances.reduce(0, +)
        let score = totalDistance + unreachableA * unreachablePenalty + unreachableB * unreachablePenalty

        print(" checking offset \(offset)")
        print(" \(a.string)")
        print(" \(b.string)")
        print(" unreachableA: \(unreachableA) (* \(unreachablePenalty))")
        print(" unreachableB: \(unreachableB) (* \(unreachablePenalty))")
        print(" reachableA: \(reachableA)")
        print(" reachableB: \(reachableB)")
        print(" totalDistance: \(totalDistance)")
        print(" #score: \(score)")
        return score

    }


}
