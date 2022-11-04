import SwiftUI
import CameraControlARView

struct ContentView: View {


    @StateObject var state: ObservableState

    @State var solver: Solver?

    init() {
        //var generator = RandomNumberGeneratorWithSeed(seed: 23232)
        //let size = 30
        //Bool.random(using: &generator)
        let size = 30

        var inputA: PixelImage<LabeledBool>
        var inputB: PixelImage<LabeledBool>

        inputA = PixelImage<LabeledBool>(width: size, height: size, pixels: stride(from: 0, to: size, by: 1).map{ y in
            return stride(from: 0, to: size, by: 1).map{ x in
                return LabeledBool(x: x, y: y, value: (y + x).isMultiple(of: 2))
            }
        }.flatMap{$0})

        inputB = PixelImage<LabeledBool>(width: size, height: size, pixels: stride(from: 0, to: size, by: 1).map{ y in
            return stride(from: 0, to: size, by: 1).map{ x in
                return LabeledBool(x: x, y: y, value: (y + x).isMultiple(of: 2))
            }
        }.flatMap{$0})

        inputA = Self.loadImage(name: "happy1").pixelImage().floydSteinbergDithered().monochromed().labeled()
        inputB = Self.loadImage(name: "happy2").pixelImage().floydSteinbergDithered().monochromed().rotatedCCW().labeled()

        self._state = StateObject(wrappedValue: ObservableState(inputA: inputA, inputB: inputB))

    }

    private static func loadImage(name: String) -> NSImage {
        guard let path = Bundle.module.path(forResource: name, ofType: "png"), let image = NSImage(contentsOfFile: path) else {
            fatalError("Couldnt load image \(name).png")
        }
        return image
    }

    var body: some View {
        ZStack(alignment: .topLeading){

            if state.show3d {
                Content3d(state: state)
            } else {
                Display(state: state)
            }

            HStack{
                Button("Toggle dots"){ state.showDots.toggle()}.foregroundColor( state.showDots ? .green : .red )
                Button("Toggle connections"){ state.showConnections.toggle()}.foregroundColor( state.showConnections ? .green : .red )
                Button("Toggle points"){ state.showPoints.toggle()}.foregroundColor( state.showPoints ? .green : .red )
                Button("Toggle strings"){ state.showStrings.toggle()}.foregroundColor( state.showStrings ? .green : .red )
                Button("Toggle strays"){ state.showStrays.toggle()}.foregroundColor( state.showStrays ? .green : .red )
                Button("Toggle 3d"){ state.show3d.toggle()}.foregroundColor( state.show3d ? .green : .red )
                Slider(value: $state.rotation, in: -Double.pi/2...(-Double.pi/2+Double.pi/2))

            }.padding()
        }
        .background(.white)
        .onAppear{
            self.solver = Solver(state: state)
        }

    }
}
