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

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var mappingStatusLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    
    var screenTouched = false
    var previousPoint: SCNVector3?
    
    var whiteBallCount = 0
    var label: UILabel!
    lazy var sphereNode: SCNNode = {
        let sphere = SCNSphere(radius: 0.005)
        sphere.firstMaterial?.diffuse.contents = UIColor.white
        return SCNNode(geometry: sphere)
    }()
    
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = true
        let scene = SCNScene()
        sceneView.scene = scene

        // Add label
        label = UILabel(frame: CGRect(x: 20, y: 20, width: 100, height: 40))
        label.textColor = UIColor.orange
        sceneView.addSubview(label)
        
        // Check to see if any previous maps have been saved
        do {
            let _ = try loadWorldMap(from: getDocumentsDirectory().appendingPathComponent("test"))
            loadButton.isHidden = false
        } catch {
            print("No previous map exists")
        }
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
    
    
    func reStartSession(withWorldMap worldMap: ARWorldMap) {
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        currentStrokeAnchorNode = nil
    }
    
    // MARK:- Drawing
    // Draws circles between points of the distance between them is greater than x
    func drawCirclesBetween(point1: SCNVector3, andPoint2 point2: SCNVector3){
        // Calculate the distance between previous point and current point
        let distance = point1.distance(vector: point2)
        let distanceBetweenEachCircle: Float = 0.00025
        let numberOfCirclesToCreate = Int(distance / distanceBetweenEachCircle)
        
        // https://math.stackexchange.com/a/83419
        // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
        let vectorBA = point2 - point1
        // Normalize vector BA by dividng it by it's length
        let vectorBANormalized = vectorBA.normalized()
        // This new vector can now be scaled and added to A to find the point at the specified distance
        guard let currentStrokeAnchorID = strokeAnchorIDs.last, let currentStrokeAnchor = anchorForID(currentStrokeAnchorID) else { return }
        for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
            let position = point1 + (vectorBANormalized * (Float(i) * distanceBetweenEachCircle))
            createSphereAndInsert(atPosition: position, andAddToStrokeAnchor: currentStrokeAnchor)
        }
    }
    
    func createSphereAndInsert(atPosition position: SCNVector3, andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        let newSphereNode = sphereNode.clone()
        newSphereNode.position = position
        // Add the node to the default node of the anchor
        guard let currentStrokeNode = currentStrokeAnchorNode else { return }
        currentStrokeNode.addChildNode(newSphereNode)
        // Add the position of the node to the stroke anchors sphereLocations array (Used for saving/loading the world map)
        strokeAnchor.sphereLocations.append([newSphereNode.position.x, newSphereNode.position.y, newSphereNode.position.z])
        whiteBallCount += 1
    }
    
    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = true
        let strokeAnchor = StrokeAnchor(name: "strokeAnchor")
        sceneView.session.add(anchor: strokeAnchor!)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
        currentStrokeAnchorNode = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
        currentStrokeAnchorNode = nil
    }
    
    
    // Gets the position of the point in front of the camera
    func getPositionInFrontOfCamera(byAmount amount: Float) -> SCNVector3? {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else { return nil }
        var translation = matrix_identity_float4x4
        translation.columns.3.x = 0
        translation.columns.3.y = 0
        translation.columns.3.z = amount
        let currentPointTransform = matrix_multiply(cameraTransform, translation)
        // Convert to SCNVector3
        return SCNVector3Make(currentPointTransform.columns.3.x,
                              currentPointTransform.columns.3.y,
                              currentPointTransform.columns.3.z)
    }
    
    func anchorForID(_ anchorID: UUID) -> StrokeAnchor? {
        return sceneView.session.currentFrame?.anchors.first(where: { $0.identifier == anchorID }) as? StrokeAnchor
    }
    
    func sortStrokeAnchorIDsInOrderOfDateCreated() {
        var strokeAnchorsArray: [StrokeAnchor] = []
        for anchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(anchorID) {
                strokeAnchorsArray.append(strokeAnchor)
            }
        }
        strokeAnchorsArray.sort(by: { $0.dateCreated < $1.dateCreated })
        
        strokeAnchorIDs = []
        for anchor in strokeAnchorsArray {
            strokeAnchorIDs.append(anchor.identifier)
        }
    }
    
    // MARK:- IBActions
    @IBAction func deleteAllButtonPressed(_ sender: UIButton) {
        for strokeAnchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(strokeAnchorID) {
                sceneView.session.remove(anchor: strokeAnchor)
            }
        }
        currentStrokeAnchorNode = nil
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        
        sortStrokeAnchorIDsInOrderOfDateCreated()
        
        guard let currentStrokeAnchorID = strokeAnchorIDs.last, let curentStrokeAnchor = anchorForID(currentStrokeAnchorID) else {
            print("No stroke to remove")
            return
        }
        sceneView.session.remove(anchor: curentStrokeAnchor)

        // add this?
        currentStrokeAnchorNode = nil

    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        saveCurrentWorldMap(forSceneView: sceneView) { (success, message) in
            if success {
                self.loadButton.isHidden = false
            } else {
                // TODO:- Show alert
            }
            print(message)
        }
    }
    
    @IBAction func loadButtonPressed(_ sender: UIButton) {
        do {
            let map = try loadWorldMap(from: getDocumentsDirectory().appendingPathComponent("test"))
            reStartSession(withWorldMap: map)
            print("Map successfuly loaded")
        } catch {
            print("Could not load the map. \(error.localizedDescription)")
        }
    }
    
    // MARK:- ARSessionDelegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        guard let currentStrokeAnchorID = strokeAnchorIDs.last else { return }
        let currentStrokeAnchor = anchorForID(currentStrokeAnchorID)
        if screenTouched && currentStrokeAnchor != nil {
            guard let currentPointPosition = getPositionInFrontOfCamera(byAmount: -0.2) else { return }

            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.00026 {
                    createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                    drawCirclesBetween(point1: previousPoint, andPoint2: currentPointPosition)
                    self.previousPoint = currentPointPosition
                }
            } else {
                createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                self.previousPoint = currentPointPosition
            }
            
            DispatchQueue.main.async {
                self.label.text = "\(self.whiteBallCount)"
            }
        }
        

        switch frame.worldMappingStatus {
        case .notAvailable:
            mappingStatusLabel.text = "not available"
            saveButton.isHidden = true
        case .limited:
            mappingStatusLabel.text = "limited"
            saveButton.isHidden = true
        case .extending:
            mappingStatusLabel.text = "extending"
            saveButton.isHidden = false
        case .mapped:
            mappingStatusLabel.text = "mapped"
            saveButton.isHidden = false
        }
    }
}

// MARK:- ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Anchor ADDED *****")
        // This should only be called when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            print("This is a stroke anchor")
            currentStrokeAnchorNode = node
            strokeAnchorIDs.append(strokeAnchor.identifier)
            for node in strokeAnchor.sphereLocations {
                createSphereAndInsert(atPosition: SCNVector3Make(node[0], node[1], node[2]), andAddToStrokeAnchor: strokeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the anchorID from the strokes array
        print("Anchor removed")
        strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
    }
}
