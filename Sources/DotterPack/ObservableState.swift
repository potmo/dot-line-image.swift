import Foundation

class ObservableState: ObservableObject {


    @Published var showDots = true
    @Published var showConnections = false
    @Published var showPoints = false
    @Published var showStrings = true
    @Published var showStrays = false
    @Published var show3d = false

    @Published var inputA: PixelImage<LabeledBool>
    @Published var inputB: PixelImage<LabeledBool>
    @Published var foundPivots: [Pivot] = []
    @Published var foundPixelsA: [LabeledBool] = []
    @Published var foundPixelsB: [LabeledBool] = []
    @Published var strayPixelsA: [LabeledBool] = []
    @Published var strayPixelsB: [LabeledBool] = []
    @Published var strayPivotsA: [Pivot] = []
    @Published var strayPivotsB: [Pivot] = []
    @Published var dependencies: [Dependency] = []

    @Published var rotation: Double = 0

    init(inputA: PixelImage<LabeledBool>, inputB: PixelImage<LabeledBool>) {
        self.inputA = inputA
        self.inputB = inputB
    }


}
