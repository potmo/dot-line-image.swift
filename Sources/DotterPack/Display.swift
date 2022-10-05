
import Foundation
import SwiftUI

struct Display: NSViewRepresentable {
    typealias NSViewType = DisplayView

    @Binding var showDots: Bool
    @Binding var showConnections: Bool
    @Binding var showPoints: Bool
    @Binding var showStrings: Bool
    @Binding var showStrays: Bool


    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> DisplayView {

        let view = DisplayView(parent: self,
                               showDots: $showDots,
                               showConnections: $showConnections,
                               showPoints: $showPoints,
                               showStrings: $showStrings,
                               showStrays: $showStrays )
        return view
    }

    func updateNSView(_ canvasView: DisplayView, context: Context) {
        canvasView.setNeedsDisplay(canvasView.bounds)
    }

 


}
