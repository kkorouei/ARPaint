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
    var label: UILabel!
    let circle: SKScene! = {
        let circle = SKShapeNode(circleOfRadius: 5) // Create circle
        circle.position = CGPoint(x: 5, y: 5)  // Center (given scene anchor point is 0.5 for x&y)
        circle.strokeColor = SKColor.clear
        circle.fillColor = SKColor.orange
        let skScene = SKScene(size: CGSize(width: 10, height: 10))
        skScene.backgroundColor = .clear
        skScene.addChild(circle)
        return skScene
    }()
    
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
            let plane = SCNPlane(width: 0.02, height: 0.02)
            plane.firstMaterial?.diffuse.contents = circle
            let planeNode = SCNNode(geometry: plane)
            planeNode.constraints = [SCNBillboardConstraint()]
            planeNode.position = point1 + (vectorBANormalized * (Float(i) * distanceBetweenEachCircle))
            self.sceneView.scene.rootNode.addChildNode(planeNode)
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
            
            let plane = SCNPlane(width: 0.02, height: 0.02)
            plane.firstMaterial?.diffuse.contents = circle
            let planeNode = SCNNode(geometry: plane)
            planeNode.constraints = [SCNBillboardConstraint()]
            
            // Move the node in front of the camera
            guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return }
            var translation = matrix_identity_float4x4
            translation.columns.3.x = 0
            translation.columns.3.y = 0
            translation.columns.3.z = -0.2
            planeNode.simdTransform = matrix_multiply(cameraTransform, translation)
            
            // Place the sphere in front of the camera
            scene.rootNode.addChildNode(planeNode)
            whiteBallCount += 1
            
            let currentPoint = planeNode.position
            if let previousPoint = previousPoint {
                let distance = abs(previousPoint.distance(vector: currentPoint))
                if distance > 0.0055 {
                    drawCirclesBetween(point1: previousPoint, andPoint2: currentPoint)
                }
            }
            self.previousPoint = currentPoint
            
            DispatchQueue.main.async {
                self.label.text = "\(self.redBallCount + self.whiteBallCount)"
            }            
        }
    }
    
}
