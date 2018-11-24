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

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
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
    
    var strokeIDs: [UUID] = []
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
        let distanceBetweenEachCircle: Float = 0.00025
        let numberOfCirclesToCreate = Int(distance / distanceBetweenEachCircle)
        
        // https://math.stackexchange.com/a/83419
        // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
        let vectorBA = point2 - point1
        // Normalize vector BA by dividng it by it's length
        let vectorBANormalized = vectorBA.normalized()
        // This new vector can now be scaled and added to A to find the point at the specified distance
        guard let currentStrokeAnchorID = strokeIDs.last, let currentStrokeAnchor = anchorForID(currentStrokeAnchorID) else { return }
        for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
            let position = point1 + (vectorBANormalized * (Float(i) * distanceBetweenEachCircle))
            createSphereAndInsert(atPosition: position, andAddToStrokeAnchor: currentStrokeAnchor)
        }
    }
    
    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = true
        let strokeAnchor = StrokeAnchor(name: "heyheyhey", capturing: sceneView)
        sceneView.session.add(anchor: strokeAnchor!)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        screenTouched = false
        previousPoint = nil
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
    
    func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: url)
    }
    
    func loadWorldMap(from url: URL) throws -> ARWorldMap {
        let mapData = try Data(contentsOf: url)
        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
            else {
                throw ARError(.invalidWorldMap)
        }
        return worldMap
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                        .userDomainMask,
                                                        true) as [String]
        return URL(fileURLWithPath: paths.first!)
    }
    
    func anchorForID(_ anchorID: UUID) -> StrokeAnchor? {
        
        return sceneView.session.currentFrame?.anchors.first(where: { $0.identifier == anchorID }) as? StrokeAnchor
        
    }
    
    // MARK:- IBActions
    @IBAction func deleteAllButtonPressed(_ sender: UIButton) {
        for strokeAnchorID in strokeIDs {
            if let strokeAnchor = anchorForID(strokeAnchorID) {
                sceneView.session.remove(anchor: strokeAnchor)
            }
        }
        strokeIDs = []
        currentStrokeAnchorNode = nil
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        
        guard let currentStrokeAnchorID = strokeIDs.last, let curentStrokeAnchor = anchorForID(currentStrokeAnchorID) else {
            print("No stroke to remove")
            return
        }
        sceneView.session.remove(anchor: curentStrokeAnchor)
        strokeIDs.removeLast(1)

        // add this?
        currentStrokeAnchorNode = nil

    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let map = worldMap else {
                // Show error
                print("Can't get world map: \(error!.localizedDescription)")
                return
            }
            // Save the map
            let pathToSave = self.getDocumentsDirectory().appendingPathComponent("test")
            do {
                try self.writeWorldMap(map, to: pathToSave)
                print("Map saved succesfully")
                self.loadButton.isHidden = false
            } catch {
                print("Could not save the map. \(error.localizedDescription)")
            }
        }
    }
    
    @IBAction func loadButtonPressed(_ sender: UIButton) {
        do {
            let map = try loadWorldMap(from: getDocumentsDirectory().appendingPathComponent("test"))
            // run a new session
            let configuration = ARWorldTrackingConfiguration()
            configuration.initialWorldMap = map
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            print("Map successfuly loaded")
        } catch {
            print("Could not load the map. \(error.localizedDescription)")
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Anchor ADDED *****")
        // This should only be called when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            print("This is a stroke anchor")
            currentStrokeAnchorNode = node
            strokeIDs.append(strokeAnchor.identifier)
            for node in strokeAnchor.sphereLocations {
                createSphereAndInsert(atPosition: SCNVector3Make(node[0], node[1], node[2]), andAddToStrokeAnchor: strokeAnchor)
            }
        }
    }
    
    // MARK:- ARSessionDelegate
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        print("The current number of anchors in the scene: \(frame.anchors.count)")
        if let firstStroke = frame.anchors.first as? StrokeAnchor {
            print("The count of spheres in the first anchor is: \(firstStroke.sphereLocations.count)")
            print("The name of the anchor is: \(firstStroke.name!)")
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

// MARK: SCNSceneRendererDelegate methods
extension ViewController {
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
//        guard let currentStrokeAnchorID = currentStrokeAnchorID else { return }
        guard let currentStrokeAnchorID = strokeIDs.last else { return }
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
    }
}
