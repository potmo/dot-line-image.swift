import Foundation
import SwiftUI
import AppKit
import RealityKit
import CameraControlARView


struct Content3d: View {

    private let arView = CameraControlARView()

    init() {

        let anchor = AnchorEntity()
        arView.scene.addAnchor(anchor)

        let box = MeshResource.generateBox(size: 0.3)
        let material = SimpleMaterial(color: .green, isMetallic: false)
        let entity = ModelEntity(mesh: box, materials: [material])

        anchor.addChild(entity)


    }

    var body: some View {
        ARViewContainer(cameraARView: arView)
    }
}
