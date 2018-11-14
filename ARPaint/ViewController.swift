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
    
    var redBallCount = 0
    var whiteBallCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene
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
    
    func drawSpheresBetween(point1: SCNVector3, andPoint2 point2: SCNVector3){
        // Calculate the distance between previous point and current point
        let distance = point1.distance(vector: point2)
        let distanceBetweenEachSphere: Float = 0.005
        let numberOfSpheresToCreate = Int(distance / distanceBetweenEachSphere)
        
        // https://math.stackexchange.com/a/83419
        // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
        let vectorBA = point2 - point1
        // Normalize vector BA by dividng it by it's length
        let vectorBANormalized = vectorBA.normalized()
        // This new vector can now be scaled and added to A to find the point at the specified distance
        
        for i in 0...numberOfSpheresToCreate {
            let sphere = SCNSphere(radius: 0.01)
            sphere.firstMaterial?.diffuse.contents = UIColor.red
            let sphereNode = SCNNode(geometry: sphere)
            print("Sphere position before: \(sphereNode.position.x), \(sphereNode.position.y), \(sphereNode.position.z)")
            sphereNode.position = point1 + (vectorBANormalized * (Float(i) * distanceBetweenEachSphere))
            print("Sphere position after: \(sphereNode.position.x), \(sphereNode.position.y), \(sphereNode.position.z)")

            // Move the spheres 20 cm in front of the camera
            var translation = matrix_identity_float4x4
            translation.columns.3.x = 0
            translation.columns.3.y = 0
            translation.columns.3.z = -0.2
            let currentSphereTransform = sphereNode.worldTransform
            let newSimd = simd_float4x4(currentSphereTransform)
            sphereNode.simdTransform = matrix_multiply(newSimd, translation)
            self.sceneView.scene.rootNode.addChildNode(sphereNode)

            redBallCount += 1
        }
    }
    
    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
    }
    
    // MARK: SCNSceneRendererDelegate methods
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if screenTouched {
            
            let sphere = SCNSphere(radius: 0.01)
            sphere.firstMaterial?.diffuse.contents = UIColor.white
            let sphereNode = SCNNode(geometry: sphere)
            sphereNode.opacity = 0.4
            
            // Move the node in front of the camera
            guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
            var translation = matrix_identity_float4x4
            translation.columns.3.x = 0
            translation.columns.3.y = 0
            translation.columns.3.z = -0.2
            sphereNode.simdTransform = matrix_multiply(cameraTransform, translation)
            
            // Place the sphere in front of the camera
            scene.rootNode.addChildNode(sphereNode)
            whiteBallCount += 1
            
            let currentPoint = SCNVector3Make(cameraTransform.columns.3.x,
                                              cameraTransform.columns.3.y,
                                              cameraTransform.columns.3.z)
            if let previousPoint = previousPoint {
                let distance = abs(previousPoint.distance(vector: currentPoint))
                if distance > 0.01 {
                    drawSpheresBetween(point1: previousPoint, andPoint2: currentPoint)
                }
            }
            self.previousPoint = currentPoint
        }
    }
    
}
