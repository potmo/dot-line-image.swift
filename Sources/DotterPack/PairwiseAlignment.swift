import Foundation

struct PairwiseAlignment<T: Equatable> {

    // adapted from: https://github.com/preston/alignment
    // propbably https://en.wikipedia.org/wiki/Smith%E2%80%93Waterman_algorithm without gap opening and gap extension penanlties

    func computeAlignment(s1: [T], s2: [T]) -> ([T?], [T?]) {
        let trace = computeScoredData(s1: s1, s2: s2)

        let rows = trace[0].count;
        let cols = trace.count;

        var output1: [T?] = []
        var output2: [T?] = []

        var curX: Int = 0
        var curY: Int = 0

        while curX < cols && curY < rows {
            var best = -1
            var bestX = curX
            var bestY = curY
            for y in curY ..< rows {
                if s2[y] == s1[curX] && trace[curX][y] > best {
                    best = trace[curX][y]
                    bestX = curX
                    bestY = y
                }
            }
            for x in curX ..< cols {
                if(s2[curY] == s1[x] && trace[x][curY] > best) {
                    best = trace[x][curY]
                    bestX = x
                    bestY = curY
                }
            }
            if best >= 0 {

                let diffX = bestX - curX;
                let diffY = bestY - curY;
                output1.append(contentsOf: Array<T?>(repeating: nil, count: diffY))
                output2.append(contentsOf: Array<T?>(repeating: nil, count: diffX))

                for i in 0 ..< diffX {
                    if curX + i > cols {
                        break
                    }
                    output1.append(s1[curX + i])
                }

                for i in 0 ..< diffY {
                    if curY + i > rows {
                        break
                    }
                    output2.append(s2[curY + i])
                }

                output1.append(s1[bestX])
                output2.append(s2[bestY])

            } else {
                output1.append(nil)
                output2.append(nil)
            }
            curX = bestX + 1
            curY = bestY + 1
        }
        // Add whatever crap is left over.
        for  i in curX ..< cols {
            output1.append(s1[i])
            output2.append(nil)

        }
        for i in curY ..< rows {
            output1.append(nil)
            output2.append(s2[i])
        }

        return (output1, output2)

    }

    func computeScoredData(s1: [T], s2: [T]) -> [[Int]] {
        let data = computeDirectMatches(s1: s1, s2: s2)

        let rows = data[0].count
        let cols = data.count
        var scored = data // copy

        for y in (0 ..< rows).reversed() {
            for x in (0 ..< cols).reversed() {

                let currentValue = data[x][y];

                let maxBelow: Int

                if x + 1 < cols {
                    maxBelow = scored[x + 1][y + 1 ..< rows].max() ?? 0
                } else {
                    maxBelow = 0
                }

                let maxRight: Int
                if y + 1 < rows {
                    maxRight = scored[x + 1  ..< cols].map{$0[y + 1]}.max() ?? 0
                } else {
                    maxRight = 0
                }


                let maxValue = max(maxBelow, maxRight)
                if maxValue >= 0 {
                    scored[x][y] = currentValue + maxValue
                } else {
                    // It's the bottom-most or right-most row, so just copy the source data row.
                    scored[x][y] = data[x][y];
                }
            }
        }
        return scored;
    }


    // generate list of direct matches
    func computeDirectMatches(s1: [T], s2: [T]) -> [[Int]] {
        let columns = s1.count
        let rows = s2.count
        var data = Array(repeating: Array(repeating: 0, count: rows), count: columns)

        for y in 0 ..< rows {
            for x in 0 ..< columns {
                if s1[x] == s2[y] {
                    data[x][y] = 1
                } else {
                    data[x][y] = 0
                }
            }
        }
        return data;
    }


    func stringify(s1: [T], s2: [T], data: [[Int]]) -> String {
        var rows = ["  " + s1.map{"\($0)"}.joined(separator: "  ")]
        for y in 0 ..< data[0].count {
            var row = "\(s2[y]) "
            for x in 0..<data.count {
                let score = data[x][y]
                if score <= 9 {
                    row += "\(score)  "
                }else {
                    row += "\(score) "
                }

            }
            rows.append(row)
        }
        return rows.joined(separator: "\n")
    }

}