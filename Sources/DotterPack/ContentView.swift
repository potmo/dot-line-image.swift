import SwiftUI
import CameraControlARView

struct ContentView: View {


    @State var showDots = true
    @State var showConnections = false
    @State var showPoints = false
    @State var showStrings = true
    @State var showStrays = false
    @State var show3d = false

    @State var inputA: PixelImage<LabeledBool>
    @State var inputB: PixelImage<LabeledBool>
    @State var foundPivots: [Pivot] = []
    @State var foundPixelsA: [LabeledBool] = []
    @State var foundPixelsB: [LabeledBool] = []
    @State var strayPixelsA: [LabeledBool] = []
    @State var strayPixelsB: [LabeledBool] = []
    @State var strayPivotsA: [Pivot] = []
    @State var strayPivotsB: [Pivot] = []

    init() {

    }

    var body: some View {
        ZStack(alignment: .topLeading){

            if show3d {
                Display(showDots: $showDots,
                        showConnections: $showConnections,
                        showPoints: $showPoints,
                        showStrings: $showStrings,
                        showStrays: $showStrays)
            } else {
                Content3d()
            }

            HStack{
                Button("Toggle dots"){ showDots.toggle()}.foregroundColor( showDots ? .green : .red )
                Button("Toggle connections"){ showConnections.toggle()}.foregroundColor( showConnections ? .green : .red )
                Button("Toggle points"){ showPoints.toggle()}.foregroundColor( showPoints ? .green : .red )
                Button("Toggle strings"){ showStrings.toggle()}.foregroundColor( showStrings ? .green : .red )
                Button("Toggle strays"){ showStrays.toggle()}.foregroundColor( showStrays ? .green : .red )
                Button("Toggle 3d"){ show3d.toggle()}.foregroundColor( show3d ? .green : .red )
            }.padding()
        }
        .background(.white)

    }
}
