
import Foundation
import SwiftUI

struct Display: NSViewRepresentable {
    typealias NSViewType = DisplayView

    init() {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> DisplayView {
        let inputA = loadImage(name: "wow-black").pixelImage()
        let inputB = loadImage(name: "wow-cool-black").pixelImage()
        let view = DisplayView(parent: self, inputA: inputA, inputB: inputB)
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
