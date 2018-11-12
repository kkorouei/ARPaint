//
//  ViewController.swift
//  ARPaint
//
//  Created by Koushan Korouei on 08/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var screenTouched = false
    var previousPoint: SCNVector3?
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        sceneView.addGestureRecognizer(tapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @objc func screenTapped(gesture: UITapGestureRecognizer) {
        guard let currentPoint = sceneView.pointOfView?.position else { return }
        if let previousPoint = previousPoint {
            // Calculate the distance between previous point and current point
            let distance = previousPoint.distance(vector: currentPoint)
            print("Distance: \(distance)")
            let distanceBetweenEachSphere: Float = 0.01
            let numberOfSpheresToCreate = Int(distance / distanceBetweenEachSphere)
            print("Number of spheres to create: \(numberOfSpheresToCreate)")
            // https://math.stackexchange.com/a/83419
            // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
            let vectorBA = currentPoint - previousPoint
            print("Vector BA = x:\(vectorBA.x), y:\(vectorBA.y) z:\(vectorBA.z)")
            // Normalize vector BA by dividng it by it's length
            let vectorBANormalized = vectorBA.normalized()
            print("vector normalized = x:\(vectorBANormalized.x), y:\(vectorBANormalized.y), z:\(vectorBANormalized.z)")
            // This new vector can now be scaled and added to A to find the point at the specified distance
            for i in 0...numberOfSpheresToCreate {
                let sphere = SCNSphere(radius: 0.01)
                sphere.firstMaterial?.diffuse.contents = UIColor.green
                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.position = previousPoint + (vectorBANormalized * (Float(i) * distanceBetweenEachSphere))
                print("Sphere added at position: x:\(sphereNode.position.x), y:\(sphereNode.position.y), z:\(sphereNode.position.z)")
                sceneView.scene.rootNode.addChildNode(sphereNode)
            }
            self.previousPoint = currentPoint
        } else {
            self.previousPoint = currentPoint
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = true
        print("Touches began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touches moved")
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        print("Touches Ended")
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        print("Touches cancelled")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if screenTouched {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else { return }
            
            let sphere = SCNSphere(radius: 0.01)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            let sphereNode = SCNNode(geometry: sphere)
            
            //                let plane = SCNPlane(width: 0.01, height: 0.01)
            //                plane.firstMaterial?.diffuse.contents = UIImage(named: "circle.png")
            //                let planeNode = SCNNode(geometry: plane)
            //                planeNode.constraints = [SCNBillboardConstraint()]
            
            var translation = matrix_identity_float4x4
            
            //Change The X Value
            translation.columns.3.x = 0
            
            //Change The Y Value
            translation.columns.3.y = 0
            
            //Change The Z Value
            translation.columns.3.z = -0
            
            sphereNode.simdTransform = matrix_multiply(currentTransform, translation)
            scene.rootNode.addChildNode(sphereNode)
        }
    }


}

extension SCNGeometry {
    class func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
