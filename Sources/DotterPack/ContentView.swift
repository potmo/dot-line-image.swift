import SwiftUI

struct ContentView: View {


    @State var showDots = true
    @State var showConnections = false
    @State var showPoints = false
    @State var showStrings = true
    init() {

    }

    var body: some View {
        ZStack(alignment: .topLeading){
            Display(showDots: $showDots,
                    showConnections: $showConnections,
                    showPoints: $showPoints,
                    showStrings: $showStrings)

            HStack{
                Button("Toggle dots"){ showDots.toggle()}.foregroundColor( showDots ? .green : .red )
                Button("Toggle connections"){ showConnections.toggle()}.foregroundColor( showConnections ? .green : .red )
                Button("Toggle points"){ showPoints.toggle()}.foregroundColor( showPoints ? .green : .red )
                Button("Toggle strings"){ showStrings.toggle()}.foregroundColor( showStrings ? .green : .red )
            }.padding()
        }

    }
}
