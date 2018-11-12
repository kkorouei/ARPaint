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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = true
        print("Touches began")
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        print("Touches Ended")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if screenTouched {
            guard let currentTransform = sceneView.session.currentFrame?.camera.transform else { return }
            // Calculate the distance between previous point and current point
            // If the distance is greater than x
            // devide x by constant to get the number of balls to place
            // place each ball along the line between previous point and current point
            
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
            translation.columns.3.z = -0.2
            
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
