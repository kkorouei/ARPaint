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
    
    var whiteBallCount = 0
    var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene

        // Add label
        label = UILabel(frame: CGRect(x: 20, y: 20, width: 100, height: 40))
        label.text = "hello"
        sceneView.addSubview(label)
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
    
    // Draws circles between points of the distance between them is greater than x
    func drawCirclesBetween(point1: SCNVector3, andPoint2 point2: SCNVector3){
        // Calculate the distance between previous point and current point
        let distance = point1.distance(vector: point2)
        let distanceBetweenEachCircle: Float = 0.0025
        let numberOfCirclesToCreate = Int(distance / distanceBetweenEachCircle)
        
        // https://math.stackexchange.com/a/83419
        // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
        let vectorBA = point2 - point1
        // Normalize vector BA by dividng it by it's length
        let vectorBANormalized = vectorBA.normalized()
        // This new vector can now be scaled and added to A to find the point at the specified distance
        for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
            let position = point1 + (vectorBANormalized * (Float(i) * distanceBetweenEachCircle))
            createSphereAndInsert(atPosition: position)
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
            
            guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
            var translation = matrix_identity_float4x4
            translation.columns.3.x = 0
            translation.columns.3.y = 0
            translation.columns.3.z = -0.2
            let currentPointTransform = matrix_multiply(cameraTransform, translation)
            // Convert to SCNVector3
            let currentPointPosition = SCNVector3Make(currentPointTransform.columns.3.x,
                                                      currentPointTransform.columns.3.y,
                                                      currentPointTransform.columns.3.z)
            
            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.0026 {
                    createSphereAndInsert(atPosition: currentPointPosition)
                    
                    drawCirclesBetween(point1: previousPoint, andPoint2: currentPointPosition)
                    self.previousPoint = currentPointPosition
                }
            } else {
                createSphereAndInsert(atPosition: currentPointPosition)
                self.previousPoint = currentPointPosition
            }
            
            DispatchQueue.main.async {
                self.label.text = "\(self.whiteBallCount)"
            }
        }
    }
    
    func createSphereAndInsert(atPosition position: SCNVector3) {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = position
        sceneView.scene.rootNode.addChildNode(sphereNode)
        whiteBallCount += 1
    }
    
}
