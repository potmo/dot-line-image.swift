
import Foundation
import SwiftUI

struct Display: NSViewRepresentable {
    typealias NSViewType = DisplayView
    
    @ObservedObject var state: ObservableState


    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> DisplayView {

        let view = DisplayView(state: state)

        return view
    }

    func updateNSView(_ canvasView: DisplayView, context: Context) {
        canvasView.setNeedsDisplay(canvasView.bounds)
    }

 


}
