import Cocoa
import SwiftUI
import AppKit

class DisplayView: NSView {

    private var trackingArea : NSTrackingArea?
    private var mousePos: CGPoint? = nil

    var parent: Display!

    @ObservedObject var state: ObservableState

    private let scale: Double = 6


    init(state: ObservableState) {

        self.state = state

        super.init(frame: .zero)
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


        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left

        let attrs = [NSAttributedString.Key.font: NSFont(name: "HelveticaNeue-Thin", size: 12)!, NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let string = "pivots: \(state.foundPivots.count), strayA: \(state.strayPixelsA.count), strayB: \(state.strayPixelsB.count)"
        string.draw(with: CGRect(x: 0, y: 0, width: 448, height: 40), options: .usesLineFragmentOrigin, attributes: attrs, context: nil)

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




        let inputSize:CGFloat = 0.2 * scale
        let offset = Point( Double(self.bounds.midX), Double(self.bounds.midX)) - Point(state.inputA.width, state.inputA.height) / 2 * scale
        let center = offset + Point(state.inputA.width, state.inputA.height) / 2 * scale

        if state.showPoints {
            context.setFillColor(CGColor(red: 0.4, green: 0.4, blue: 1, alpha: 1.0))
            
            for x in 0 ..< state.inputA.width {
                for y in 0 ..< state.inputA.height {
                    if state.inputA[x,y].value {
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

            context.setFillColor(CGColor(red: 0, green: 0, blue: 0.5, alpha: 1.0))
            for strayPixel in state.strayPixelsA {

                context.beginPath()
                context.addArc(center: (offset + Point(strayPixel.x,strayPixel.y) * scale).cgPoint,
                               radius: inputSize,
                               startAngle: CGFloat.pi * 0.5,
                               endAngle: CGFloat.pi * 1.0,
                               clockwise: false)
                context.addLine(to: (offset + Point(strayPixel.x,strayPixel.y) * scale).cgPoint)
                context.fillPath()
            }
            
            context.setFillColor(CGColor(red: 0.5, green: 1, blue: 0.5, alpha: 1.0))
            
            for x in 0 ..< state.inputB.width {
                for y in 0 ..< state.inputB.height {
                    if state.inputB[x, y].value   {
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

            context.setFillColor(CGColor(red: 0, green: 0.5, blue: 0, alpha: 1.0))
            for strayPixel in state.strayPixelsB {

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


        if state.showConnections {
            for pivot in state.foundPivots {

                let start = offset + pivot.dotPoint * scale
                let end = (offset + pivot.pivotPoint * scale).rotated(around: center, by: -.pi / 2)
                let arrow = (end - start).normalized().negated()
                let arrowLeft = end + arrow.rotated(around: Point(0,0), by: .pi * 0.05) * scale * 0.2
                let arrowRight = end + arrow.rotated(around: Point(0,0), by: -.pi * 0.05) * scale * 0.2

                context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
                context.beginPath()
                context.move(to: start.cgPoint)
                context.addLine(to: end.cgPoint)

                context.addLine(to: arrowLeft.cgPoint)
                context.move(to: end.cgPoint)
                context.addLine(to: arrowRight.cgPoint)
                context.strokePath()

            }
        }



        let angle: Double = state.rotation

//        if let mousePos {
//            angle = (mousePos.y / Double(frame.height) * Double.pi * 4)
//        } else {
//            angle = 0
//        }

        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.9))
        context.beginPath()
        context.addArc(center: center.cgPoint, radius: 300, startAngle: 0 - angle, endAngle: CGFloat.pi - angle, clockwise: true)
        context.strokePath()

        if state.showDots {
            for pivot in state.foundPivots {

              drawPivot(pivot,
                        to: context,
                        with: CGColor(red: 1, green: 0, blue: 0, alpha: 1),
                        offset: offset,
                        center: center,
                        angle: angle)
            }

            if state.showStrays {
                for pivot in state.strayPivotsA {
                    drawPivot(pivot,
                              to: context,
                              with: CGColor(red: 1, green: 0, blue: 0, alpha: 1.0),
                              offset: offset,
                              center: center,
                              angle: angle)
                }

                for pivot in state.strayPivotsB {
                    drawPivot(pivot,
                              to: context,
                              with: CGColor(red: 1, green: 0, blue: 0, alpha: 1.0),
                              offset: offset,
                              center: center,
                              angle: angle)
                }
            }
        }


       drawOriginals(context: context)

    }

    func drawOriginals(context: CGContext) {

        let scale = 3.0
        let offset = Point(50, 50)
        let offsetA = Point(0, state.inputA.height) * scale + offset
        let offsetB = Point(state.inputA.width, state.inputA.height) * scale + offset
        let offsetC = Point(state.inputA.width, 0) * scale + offset

        let bPivotPoint = Point(state.inputB.width, state.inputB.height) / 2

        context.setStrokeColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))
        context.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1))

        for pixel in state.foundPixelsA.map(\.point) {
            context.beginPath()
            context.addArc(center: (offsetA + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }

        for pixel in state.foundPixelsB.map(\.point).map({$0.rotated(around: bPivotPoint, by: -.pi/2)}) {
            context.beginPath()
            context.addArc(center: (offsetB + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }

        for pixel in state.foundPixelsB.map(\.point) {
            context.beginPath()
            context.addArc(center: (offsetC + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }

        context.setStrokeColor(CGColor(red: 1, green: 0, blue: 1, alpha: 0.2))
        context.setFillColor(CGColor(red: 1, green: 0, blue: 1, alpha: 0.2))
        for pixel in state.strayPixelsA.map(\.point) {
            context.beginPath()
            context.addArc(center: (offsetA + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }

        for pixel in state.strayPixelsB.map(\.point).map({$0.rotated(around: bPivotPoint, by: -.pi/2)}) {
            context.beginPath()
            context.addArc(center: (offsetB + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }

        for pixel in state.strayPixelsB.map(\.point) {
            context.beginPath()
            context.addArc(center: (offsetC + pixel * scale).cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
            context.fillPath()
        }
    }


    func drawPivot(_ pivot: Pivot, to context: CGContext, with color: CGColor, offset: Point, center: Point, angle: Double) {

        let hangAngle = Double.pi / 2 + angle

        let pivotPoint = offset + Point(pivot.x, pivot.y) * scale

        let tipPoint = pivotPoint + Point(cos(hangAngle), sin(hangAngle)) * scale * pivot.length

        let pivotPointRotated = pivotPoint.rotated(around: center, by: angle)
        let tipPointRotated = tipPoint.rotated(around: center, by: angle)

        if state.showStrings {
            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
            context.beginPath()
            context.addArc(center: pivotPointRotated.cgPoint, radius: 0.2, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
            context.strokePath()

            context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.05))
            context.beginPath()
            context.move(to: pivotPointRotated.cgPoint)
            context.addLine(to: tipPointRotated.cgPoint)
            context.strokePath()
        }

        context.setStrokeColor(color)
        context.setFillColor(color)
        context.beginPath()
        context.addArc(center: tipPointRotated.cgPoint, radius: 1, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
        context.fillPath()
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
