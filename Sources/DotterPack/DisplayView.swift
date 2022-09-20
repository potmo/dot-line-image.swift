import Cocoa
import SwiftUI

class DisplayView: NSView {

    private var trackingArea : NSTrackingArea?
    private var mousePos: CGPoint? = nil

    var parent: Display!

    private let inputA: PixelImage<Bool>
    private let inputB: PixelImage<Bool>
    private let found: [Pivot]

    private var showInput = false

    init(parent: Display, inputA: PixelImage<Pixel>, inputB: PixelImage<Pixel>) {

        var inputA = inputA.floydSteinbergDithered().monochromed()
        var inputB = inputB.floydSteinbergDithered().rotatedCCW().monochromed()
        let aligner = PairwiseAlignment<Bool>()


        Task{
            print("start")
            let matrix1 = inputA.matrix
            let matrix2 = inputB.matrix
            print("matrix done")
            let result = aligner.computeDiagonalAlignments(matrix1: matrix1, matrix2: matrix2)
            print("done")
        }



        //print(alignmentA.map{ $0 == nil ? "-" : "\($0! ? 1 : 0)"}.joined())
        //print(alignmentB.map{ $0 == nil ? "-" : "\($0! ? 1 : 0)"}.joined())


        self.inputA = inputA
        self.inputB = inputB


        var found: [Pivot] = []

        // find direct hits
        for x in 0..<inputA.width {
            for y in 0..<inputA.height {
                if inputA[x,y] && inputB[x, y] {
                    inputA[x,y] = false
                    inputB[x,y] = false
                    found.append(Pivot(x: x, y: y, length: 0))
                }
            }
        }

        let maxDiagonal = Int((sqrt(pow(Double(inputA.width),2) + pow(Double(inputA.height),2))).rounded(.up))

        for x in 0..<inputA.width {
            for y in 0..<inputA.height {
                if inputA[x,y] {
                    for d in 0 ..< maxDiagonal {
                        guard inputB.contains(x+d, y-d) else {
                            break
                        }
                        if inputB[x+d, y-d] {
                            found.append(Pivot(x: x, y: y-d, length: d))
                            inputA[x,y] = false
                            inputB[x+d,y-d] = false
                            break
                        }
                    }
                }
            }
        }


        self.found = found
        


        super.init(frame: NSRect(x: 0, y: 0, width: 1000, height: 1000))
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
        let offset = Point(100, 200)

        if showInput {
            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1.0))
            
            for x in 0 ..< inputA.width {
                for y in 0 ..< inputA.height {
                    if inputA[x,y] {
                        context.beginPath()
                        context.addArc(center: (offset + Point(x,y) * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
                        context.strokePath()
                    }
                }
            }
            
            
            context.setStrokeColor(CGColor(red: 0, green: 1, blue: 0, alpha: 1.0))
            
            for x in 0 ..< inputB.width {
                for y in 0 ..< inputB.height {
                    if inputB[x, y]   {
                        context.beginPath()
                        let point = offset + Point(x,y) * scale
                        context.addArc(center: point.cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
                        context.strokePath()
                    }
                }
            }
        }

        let angle: Double

        if let mousePos {
            angle = (mousePos.y / Double(frame.height) * Double.pi * 4)
        } else {
            angle = 0
        }

        let hangAngle = Double.pi / 2 + angle

        let center = offset + Point(inputA.width, inputA.height) / 2 * scale


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
