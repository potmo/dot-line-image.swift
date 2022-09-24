import Cocoa
import SwiftUI

class DisplayView: NSView {

    private var trackingArea : NSTrackingArea?
    private var mousePos: CGPoint? = nil

    var parent: Display!

    private let inputA: PixelImage<LabeledBool>
    private let inputB: PixelImage<LabeledBool>
    private var found: [Pivot]
    private var strayPixelsA: [LabeledBool]
    private var strayPixelsB: [LabeledBool]

    private var showInput = false

    init(parent: Display, inputA: PixelImage<Pixel>, inputB: PixelImage<Pixel>) {

        self.found = []
        self.strayPixelsA = []
        self.strayPixelsB = []
        self.inputA = inputA.floydSteinbergDithered().monochromed().labeled()
        self.inputB = inputB.floydSteinbergDithered().rotatedCCW().monochromed().labeled()

        /*
        var generator = RandomNumberGeneratorWithSeed(seed: 23232)

        self.inputA = PixelImage<LabeledBool>(width: 10, height: 10, pixels: stride(from: 0, to: 10, by: 1).map{ x in
            return stride(from: 0, to: 10, by: 1).map{ y in
                return LabeledBool(x: x, y: y, value: Bool.random(using: &generator)) // Bool.random(using: &generator)
            }
        }.flatMap{$0})


        self.inputB = PixelImage<LabeledBool>(width: 10, height: 10, pixels: stride(from: 0, to: 10, by: 1).map{ x in
            return stride(from: 0, to: 10, by: 1).map{ y in
                return LabeledBool(x: x, y: y, value: Bool.random(using: &generator)) // Bool.random(using: &generator)
            }
        }.flatMap{$0})*/

        super.init(frame: NSRect(x: 0, y: 0, width: 1000, height: 1000))


        print("inputA")
        printMatrix(self.inputA.matrix) { $0.value ? "■" : "□"}

        print("inputB")
        printMatrix(self.inputB.matrix) { $0.value ? "■" : "□"}

        print("//////////")

        Task{

            let startDiagonalsA = self.inputA.diagonals
            let startDiagonalsB = self.inputB.diagonals

            //first take all direct hits and add them as pivots
            let (diagonalsA, diagonalsB) = await self.getDiagonalsWithoutDirectHits(startDiagonalsA: startDiagonalsA, startDiagonalsB: startDiagonalsB)

            let alignments = await self.getAlignments(diagonalsA: diagonalsA, diagonalsB: diagonalsB)

            //printAlignments(of: alignments, diagonalsA: diagonalsA, diagonalsB: diagonalsB)

            // find all pixels that match after aligning
            _ = await self.getNonMatchingAlignments(alignments: alignments)

            //print("XXXXXXXXXXXX After XXXXXXXXXXXX")
            //printAlignments(of: nonMathingAlignments, diagonalsA: diagonalsA, diagonalsB: diagonalsB)

            (strayPixelsA, strayPixelsB) = await self.getStrayPixels(startDiagonalsA: startDiagonalsA, startDiagonalsB: startDiagonalsB)

        }
    }

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

    func getAlignments(diagonalsA: [[LabeledBool]], diagonalsB: [[LabeledBool]]) async -> [([LabeledBool?], [LabeledBool?])] {
        let aligner = PairwiseAlignment<LabeledBool>()

        return await zip(diagonalsA, diagonalsB)
            .asyncMap{ diagonalA, diagonalB in
                let alignment = await aligner.computeAlignment(s1: diagonalA, s2: diagonalB)
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
                    Int(pivot.posA.x) == pixel.x && Int(pivot.posA.y) == pixel.y
                })
            }

        let pixelsB = startDiagonalsB.flatMap{$0}
        let blackPixelsB = pixelsB.filter{pixel in return pixel.value}
        let strayPixelsB = blackPixelsB.filter{ pixel in
            return !found.contains(where: { pivot in
                Int(pivot.posB.x) == pixel.x && Int(pivot.posB.y) == pixel.y
            })
        }


        return (strayPixelsA, strayPixelsB)
    }


    override init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else {
            print("no context")
            return
        }

        // flip y-axis so origin is in top left corner
        let flipVerticalTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: self.frame.size.height)
        context.concatenate(flipVerticalTransform)
        context.setStrokeColor(CGColor.init(red: 1, green: 0, blue: 0, alpha: 1))
        context.setLineWidth(1.0)

        if let mousePos {
            context.setLineDash(phase: 0, lengths: [])
            context.beginPath()
            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
            context.addArc(center: mousePos, radius: 5, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
            context.strokePath()
        }


        let scale: Double = 6
        let inputSize:CGFloat = 5
        let offset = Point( Double(self.bounds.midX), Double(self.bounds.midX)) - Point(inputA.width, inputA.height) / 2 * scale
        let center = offset + Point(inputA.width, inputA.height) / 2 * scale

        if showInput {
            context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1.0))
            
            for x in 0 ..< inputA.width {
                for y in 0 ..< inputA.height {
                    if inputA[x,y].value {
                        context.beginPath()
                        context.addArc(center: (offset + Point(x,y) * scale).cgPoint,
                                       radius: inputSize,
                                       startAngle: CGFloat.pi * 0.0,
                                       endAngle: CGFloat.pi * 1.0,
                                       clockwise: false)
                        context.fillPath()
                    }
                }
            }

            context.setFillColor(CGColor(red: 1, green: 0, blue: 1, alpha: 1.0))
            for strayPixel in strayPixelsA {

                context.beginPath()
                context.addArc(center: (offset + Point(strayPixel.x,strayPixel.y) * scale).cgPoint,
                               radius: inputSize,
                               startAngle: CGFloat.pi * 0.5,
                               endAngle: CGFloat.pi * 1.0,
                               clockwise: false)
                context.addLine(to: (offset + Point(strayPixel.x,strayPixel.y) * scale).cgPoint)
                context.fillPath()
            }
            
            context.setFillColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1.0))
            
            for x in 0 ..< inputB.width {
                for y in 0 ..< inputB.height {
                    if inputB[x, y].value   {
                        context.beginPath()
                        let point = (offset + Point(x,y) * scale).rotated(around: center, by: -Double.pi / 2)

                        context.addArc(center: point.cgPoint, radius: inputSize,
                                       startAngle: CGFloat.pi * 1.0,
                                       endAngle: CGFloat.pi * 2.0,
                                       clockwise: false)
                        context.fillPath()
                    }
                }
            }

            context.setFillColor(CGColor(red: 1, green: 0, blue: 1, alpha: 1.0))
            for strayPixel in strayPixelsB {

                context.beginPath()
                let point = (offset + Point(strayPixel.x,strayPixel.y) * scale).rotated(around: center, by: -Double.pi / 2)
                context.addArc(center: point.cgPoint,
                               radius: inputSize,
                               startAngle: CGFloat.pi * 1.5,
                               endAngle: CGFloat.pi  * 2.0,
                               clockwise: false)
                context.addLine(to: point.cgPoint)
                context.fillPath()
            }
        }

        let angle: Double

        if let mousePos {
            angle = (mousePos.y / Double(frame.height) * Double.pi * 4)
        } else {
            angle = 0
        }

        let hangAngle = Double.pi / 2 + angle




        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.9))
        context.beginPath()
        context.addArc(center: center.cgPoint, radius: 300, startAngle: 0 - angle, endAngle: CGFloat.pi - angle, clockwise: true)
        context.strokePath()

        for pivot in found {

            let pivotPoint = offset + Point(pivot.x, pivot.y) * scale

            let tipPoint = pivotPoint + Point(cos(hangAngle), sin(hangAngle)) * scale * pivot.length

            let pivotPointRotated = pivotPoint.rotated(around: center, by: angle)
            let tipPointRotated = tipPoint.rotated(around: center, by: angle)

            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
            context.beginPath()
            context.addArc(center: pivotPointRotated.cgPoint, radius: 0.5, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
            context.strokePath()

            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.05))
            context.beginPath()
            context.move(to: pivotPointRotated.cgPoint)
            context.addLine(to: tipPointRotated.cgPoint)
            context.strokePath()

            context.setStrokeColor(CGColor(red: 255, green: 0, blue: 0, alpha: 1))
            context.setFillColor(CGColor(red: 255, green: 0, blue: 0, alpha: 1))
            context.beginPath()
            context.addArc(center: tipPointRotated.cgPoint, radius: 2, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
            context.fillPath()
        }

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


    override func updateTrackingAreas() {
        if trackingArea != nil {
            self.removeTrackingArea(trackingArea!)
        }
        let options : NSTrackingArea.Options =
        [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow]

        trackingArea = NSTrackingArea(rect: self.bounds,
                                      options: options,
                                      owner: self,
                                      userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        let flipVerticalTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: self.frame.size.height)
        let local = self.convert(event.locationInWindow, from: nil).applying(flipVerticalTransform)
        mousePos = local
        setNeedsDisplay(self.bounds)
    }

    override func mouseExited(with event: NSEvent) {
        mousePos = nil
        setNeedsDisplay(self.bounds)
    }

    override func mouseMoved(with event: NSEvent) {
        let flipVerticalTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: self.frame.size.height)
        let local = self.convert(event.locationInWindow, from: nil).applying(flipVerticalTransform)
        mousePos = local
        setNeedsDisplay(self.bounds)
    }

    private var initialTouch: NSTouch?
    override func touchesBegan(with event: NSEvent) {
        let initialTouches = event.touches(matching: .touching, in: self)

        guard initialTouches.count == 2 else {
            return
        }

        guard let initialTouch = initialTouches.first else {
            return
        }

        self.initialTouch = initialTouch

    }

    override func touchesMoved(with event: NSEvent) {
        //        print("toches \(event.allTouches().count)")

        guard event.touches(matching: .touching, in: self).count == 2 else {
            return
        }

        guard let previousTouch = initialTouch else {
            return
        }

        guard let currentTouch = event.touches(matching: .touching, in: self).first(where: {$0.identity.isEqual( previousTouch.identity)}) else {
            return
        }

        let previousPos = CGPoint(x: previousTouch.normalizedPosition.x * previousTouch.deviceSize.width,
                                  y: previousTouch.normalizedPosition.y * previousTouch.deviceSize.height)

        let currentPos = CGPoint(x: currentTouch.normalizedPosition.x * currentTouch.deviceSize.width,
                                 y: currentTouch.normalizedPosition.y * currentTouch.deviceSize.height)

        _ = CGPoint(x: previousPos.x - currentPos.x, y: previousPos.y - currentPos.y)

        self.initialTouch = currentTouch


        setNeedsDisplay(self.bounds)

    }
    override func mouseDown(with event: NSEvent) {
        //let flipVerticalTransform = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: self.frame.size.height)
        //let local = self.convert(event.locationInWindow, to: self).applying(flipVerticalTransform)
        //self.mousePos = local

        showInput = !showInput

        setNeedsDisplay(self.bounds)
    }

    override func mouseUp(with event: NSEvent) {
        //        let local = self.convert(event.locationInWindow, to: self)
        //        print("mouse up \(local.x) \(local.y)")
    }

    override func magnify(with event: NSEvent) {

        //let zoomFactor = 1 / (1 - event.magnification)
        //let position = self.convert(event.locationInWindow, to: self)
        //let balance = position.x / bounds.width

        setNeedsDisplay(self.bounds)
    }

    override func rightMouseDragged(with event: NSEvent) {

    }

 
}
