
import Foundation
import SwiftUI

struct Display: NSViewRepresentable {
    typealias NSViewType = DisplayView

    @Binding var showDots: Bool
    @Binding var showConnections: Bool
    @Binding var showPoints: Bool
    @Binding var showStrings: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> DisplayView {
        let inputA = loadImage(name: "bergman").pixelImage()
        let inputB = loadImage(name: "bergman").pixelImage()
        let view = DisplayView(parent: self,
                               imageA: inputA,
                               imageB: inputB,
                               showDots: $showDots,
                               showConnections: $showConnections,
                               showPoints: $showPoints,
                               showStrings: $showStrings)
        return view
    }

    func updateNSView(_ canvasView: DisplayView, context: Context) {
        canvasView.setNeedsDisplay(canvasView.bounds)
    }

    func loadImage(name: String) -> NSImage {
        guard let path = Bundle.module.path(forResource: name, ofType: "png"), let image = NSImage(contentsOfFile: path) else {
            fatalError("Couldnt load image \(name).png")
        }
        return image
    }


}
