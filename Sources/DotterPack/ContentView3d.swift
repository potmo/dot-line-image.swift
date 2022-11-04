import Foundation
import SwiftUI
import AppKit
import RealityKit
import CameraControlARView
import Combine
import simd

struct Content3d: View {

    @ObservedObject private var state: ObservableState
    @State private var cancellables: Set<AnyCancellable> = Set()

    @StateObject private var arView: CameraControlARView = {
        let arView = CameraControlARView(frame: .zero)

        // Set ARView debug options
        arView.debugOptions = [
            .none
        ]

        let anchor = AnchorEntity()
        arView.scene.addAnchor(anchor)


/*
        let directionalLight = DirectionalLight()
        anchor.addChild(directionalLight)

        directionalLight.light.color = .white
        directionalLight.light.intensity = 20000

        directionalLight.orientation = simd_quatf(angle: -.pi/1.5, axis: [0,1,0])
        directionalLight.look(at: anchor.position, from: [0,5,5], relativeTo: nil)
        */

        return arView
    }()

    @State private var pivotEntities: [Entity] = []



    init(state: ObservableState) {
        self.state = state
    }

    private func dependencyPivots(dependencies: [Dependency]) {

        if dependencies.isEmpty {
            return
        }

        guard let anchor = arView.scene.anchors.first(where: {$0 != arView.cameraAnchor}) else {
            fatalError("no anchor found")
        }

        for child in pivotEntities {
            child.removeFromParent()
        }

        pivotEntities = []

        let dotMaterial = SimpleMaterial(color: .red, isMetallic: false)
        let dotMesh = MeshResource.generateSphere(radius: 1)

        let textMaterial = SimpleMaterial(color: .blue, isMetallic: false)



        let stringMaterial = SimpleMaterial(color: .darkGray, isMetallic: false)
        let stringMesh = MeshResource.generateBox(width: 1, height: 1, depth: 1)
        let backgroundMaterial = SimpleMaterial(color: .yellow, isMetallic: false)

        let backgroundEntity = ModelEntity(mesh: stringMesh, materials: [backgroundMaterial])
        anchor.addChild(backgroundEntity)
        backgroundEntity.scale = [1,1,0.001]
        backgroundEntity.position -= [0,0,0]

        
        for dependency in dependencies {

            let pivot = dependency.pivot

            let pivotZ = Double(dependency.depth + 1) * 0.3

            let dotEntity = ModelEntity(mesh: dotMesh, materials: [dotMaterial])
            let pivotEntity = Entity()
            pivotEntity.addChild(dotEntity)
            dotEntity.position = [0, -pivot.length, 0] * 0.01
            dotEntity.scale = [ 0.4, 0.4, 0.3] * 0.01


            let textMesh = MeshResource.generateText("\(dependency.rootId):\(dependency.depth)", alignment: .center)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            pivotEntity.addChild(textEntity)
            textEntity.position = [0 - dotEntity.scale.x / 2 * 100, -pivot.length - dotEntity.scale.y / 2 * 100, dotEntity.scale.z * 100] * 0.01
            textEntity.scale = [ 0.05, 0.05, 0.05] * 0.01

            let stringEntity = ModelEntity(mesh: stringMesh, materials: [stringMaterial])
            pivotEntity.addChild(stringEntity)
            stringEntity.position = [0, -pivot.length / 2, 0] * 0.01
            stringEntity.scale = [0.05, pivot.length, 0.05] * 0.01

            let rodEntity = ModelEntity(mesh: stringMesh, materials: [stringMaterial])
            pivotEntity.addChild(rodEntity)
            rodEntity.position = [0, 0, -pivotZ/2] * 0.01
            rodEntity.scale = [0.1, 0.1, pivotZ] * 0.01


            anchor.addChild(pivotEntity)
            let halfSize: SIMD3<Double> = [Double(state.inputA.width), -Double(state.inputA.height), 0] / 2 * 0.01
            pivotEntity.position = [pivot.x, -pivot.y, pivotZ] * 0.01 - halfSize

            pivotEntities.append(pivotEntity)

        }
    }

    private func updateRotation(rotation: Double) {
        guard let anchor = arView.scene.anchors.first(where: {$0 != arView.cameraAnchor}) else {
            fatalError("no anchor found")
        }

        anchor.orientation = simd_quatd(angle: rotation, axis: [0, 0, 1])

        for child in pivotEntities {
            child.orientation = simd_quatd(angle: -rotation, axis: [0, 0, 1])
        }

    }

    var body: some View {
        ARViewContainer(cameraARView: arView)
            .onAppear{
                state.$dependencies
                    .sink(receiveValue: self.dependencyPivots(dependencies:))
                    .store(in: &cancellables)

                /*
                arView.scene.subscribe(to: SceneEvents.Update.self) { event in
                    self.tick(delta: event.deltaTime)
                }.store(in: &cancellables)*/

                state.$rotation
                    .sink(receiveValue: self.updateRotation(rotation:))
                    .store(in: &cancellables)
            }
    }
}


extension Entity {
    var position: SIMD3<Double> {
        get {
            let floatPosition: SIMD3<Float> = self.position
            return [Double(floatPosition.x), Double(floatPosition.y),Double(floatPosition.z)]
        }
        set {
            let floatPosition: SIMD3<Float> = [Float(newValue.x), Float(newValue.y), Float(newValue.z)]
            self.position = floatPosition
        }
    }

    var scale: SIMD3<Double> {
        get {
            let floatScale: SIMD3<Float> = self.scale
            return [Double(floatScale.x), Double(floatScale.y),Double(floatScale.z)]
        }
        set {
            let floatScale: SIMD3<Float> = [Float(newValue.x), Float(newValue.y), Float(newValue.z)]
            self.scale = floatScale
        }
    }

    var orientation: simd_quatd {
        get {
            let floatOrientation: simd_quatf = self.orientation
            return simd_quatd(angle: Double(floatOrientation.angle),
                              axis: [ Double(floatOrientation.axis.x), Double(floatOrientation.axis.y), Double(floatOrientation.axis.z) ] )
        }
        set {
            let floatOrientation = simd_quatf(angle: Float(newValue.angle),
                                              axis: [ Float(newValue.axis.x), Float(newValue.axis.y), Float(newValue.axis.z) ] )
            self.orientation = floatOrientation
        }
    }
}
