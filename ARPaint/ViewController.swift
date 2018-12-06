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

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var trackingStateLabel: UILabel!
    @IBOutlet weak var worldMappingStateLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var preparingDrawingAreaView: UIVisualEffectView!
    @IBOutlet weak var preparingDrawingAreaLabel: UILabel!
    @IBOutlet weak var additionalButtonsView: UIView!
    @IBOutlet weak var BrushColorSelectionView: UIView!
    @IBOutlet weak var saveLoadSelectionView: UIView!
    @IBOutlet weak var menuButtonsView: UIView!
    @IBOutlet weak var resetTrackingView: UIView!
    
    var previousPoint: SCNVector3?
    var currentFingerPosition: CGPoint?
    
    var screenShotOverlayImageView: UIImageView?
    
    var whiteBallCount = 0
    var label: UILabel!
    
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    
    var isLoadingSavedWorldMap = false
    
    var currentStrokeColor: StrokeColor = .red
    
    // MARK:- View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent the screen from being dimmed
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.preferredFramesPerSecond = 60
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.showsStatistics = false
        let scene = SCNScene()
        sceneView.scene = scene

        // Add label
        label = UILabel(frame: CGRect(x: 20, y: 20, width: 100, height: 40))
        label.textColor = UIColor.orange
        sceneView.addSubview(label)
        
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        // Add long press gesture to undo button
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressUndoButton))
        undoButton.addGestureRecognizer(longPressGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func hideAllUI() {
        DispatchQueue.main.async {
            self.menuButtonsView.isHidden = true
            self.resetTrackingView.isHidden = true
            self.additionalButtonsView.isHidden = true
        }
    }
    
    func showAllUI() {
        DispatchQueue.main.async {
            self.menuButtonsView.isHidden = false
            self.resetTrackingView.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAllDrawingsVC" {
            let navigationController = segue.destination as! UINavigationController
            let drawingsViewController = navigationController.viewControllers[0] as! AllDrawingsViewController
            drawingsViewController.delegate = self
            let fetchedDrawings =  fetchAllDrawingsFromCoreData()
            drawingsViewController.drawings = fetchedDrawings
            
            if screenShotOverlayImageView != nil {
                screenShotOverlayImageView!.removeFromSuperview()
                screenShotOverlayImageView = nil
            }
        }
    }
    
    
    func reStartSession(withWorldMap worldMap: ARWorldMap?) {
        let configuration = ARWorldTrackingConfiguration()
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            isLoadingSavedWorldMap = true
            hideAllUI()
        } else {
            sceneView.session.run(configuration, options: [.resetTracking])
        }
        currentStrokeAnchorNode = nil
    }
    
    // MARK:- Drawing
    func createSphereAndInsert(atPositions positions: [SCNVector3], andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        for position in positions {
            createSphereAndInsert(atPosition: position, andAddToStrokeAnchor: strokeAnchor)
        }
    }
    
    func createSphereAndInsert(atPosition position: SCNVector3, andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        guard let currentStrokeNode = currentStrokeAnchorNode else { return }
        // Get the reference sphere node and clone it
        let referenceSphereNode = getReferenceSphereNode(forStrokeColor: strokeAnchor.color)
        let newSphereNode = referenceSphereNode.clone()
        // Convert the position from world transform to local transform (relative to the anchors default node)
        let localPosition = currentStrokeNode.convertPosition(position, from: nil)
        newSphereNode.position = localPosition
        // Add the node to the default node of the anchor
        currentStrokeNode.addChildNode(newSphereNode)
        // Add the position of the node to the stroke anchors sphereLocations array (Used for saving/loading the world map)
        strokeAnchor.sphereLocations.append([newSphereNode.position.x, newSphereNode.position.y, newSphereNode.position.z])
        whiteBallCount += 1
    }
    
    // MARK: Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Hide the additional buttons view if it's showing
        additionalButtonsView.isHidden = true
        // Create a StrokeAnchor and add it to the Scene (One Anchor will be added to the exaction position of the first sphere for every new stroke)
        guard let touch = touches.first else { return }
        guard let touchPositionInFrontOfCamera = getPosition(ofPoint: touch.location(in: sceneView), atDistanceFromCamera: 0.2, inView: sceneView) else { return }
        // Convert the position from SCNVector3 to float4x4
        let strokeAnchor = StrokeAnchor(name: "strokeAnchor", transform: float4x4(float4(1, 0, 0, 0),
                                                                                  float4(0, 1, 0, 0),
                                                                                  float4(0, 0, 1, 0),
                                                                                  float4(touchPositionInFrontOfCamera.x,
                                                                                         touchPositionInFrontOfCamera.y,
                                                                                         touchPositionInFrontOfCamera.z,
                                                                                         1)))
        strokeAnchor.color = currentStrokeColor
        sceneView.session.add(anchor: strokeAnchor)
        currentFingerPosition = touch.location(in: sceneView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentFingerPosition = touch.location(in: sceneView)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentFingerPosition = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentFingerPosition = nil
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
    
    @objc func longPressUndoButton(gesture: UILongPressGestureRecognizer) {
        print("long pressed")
        for strokeAnchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(strokeAnchorID) {
                sceneView.session.remove(anchor: strokeAnchor)
            }
        }
        currentStrokeAnchorNode = nil
    }
    
    @IBAction func resetTrackingButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
        reStartSession(withWorldMap: nil)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
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
        guard let currentFrame = sceneView.session.currentFrame else { return }
        switch currentFrame.worldMappingStatus {
        case .notAvailable, .limited:
        // TODO: show label saying it's unavailable
            print("Move around your phone a bit")
        case .extending, .mapped:
            additionalButtonsView.isHidden = true
            saveCurrentDrawingToCoreData(forSceneView: sceneView) { (success, message) in
                if success {
                } else {
                    // TODO:- Show alert
                }
                print(message)
            }
        }
    }
    
    @IBAction func loadButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "showAllDrawingsVC", sender: self)
        additionalButtonsView.isHidden = true
    }
    @IBAction func changeColorButtonPressed(_ sender: UIButton) {
        if additionalButtonsView.isHidden {
            BrushColorSelectionView.isHidden = false
            saveLoadSelectionView.isHidden = true
            additionalButtonsView.isHidden = false
        } else {
            // Hide the additionalButtonsView if the color buttons are already showing
            if saveLoadSelectionView.isHidden {
                additionalButtonsView.isHidden = true
            } else {
                BrushColorSelectionView.isHidden = false
                saveLoadSelectionView.isHidden = true
            }
        }
    }
    
    // Brush Colors changed
    // TODO: Make them into action outlet
    @IBAction func redColorButtonPressed(_ sender: Any) {
        currentStrokeColor = .red
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func greenColorButtonPressed(_ sender: Any) {
        currentStrokeColor = .green
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func blueColorButtonPressed(_ sender: Any) {
        currentStrokeColor = .blue
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func blackColorButtonPressed(_ sender: Any) {
        currentStrokeColor = .black
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func whiteColorButtonPressed(_ sender: Any) {
        currentStrokeColor = .white
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func saveLoadButtonPressed(_ sender: UIButton) {
        if additionalButtonsView.isHidden {
            saveLoadSelectionView.isHidden = false
            BrushColorSelectionView.isHidden = true
            additionalButtonsView.isHidden = false
        } else {
            // Hide the additionalButtonsView if the save/load buttons are already showing
            if BrushColorSelectionView.isHidden {
                additionalButtonsView.isHidden = true
            } else {
                BrushColorSelectionView.isHidden = true
                saveLoadSelectionView.isHidden = false
            }
        }
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
        let image = sceneView.snapshot()
        
        let screenShotNavigationController = storyboard?.instantiateViewController(withIdentifier: "screenShotNav") as! UINavigationController
        let screenShotViewController = screenShotNavigationController.viewControllers[0] as! ScreenShotViewController
        screenShotViewController.screenShotImage = image
        screenShotNavigationController.modalPresentationStyle = .overCurrentContext
        present(screenShotNavigationController, animated: true, completion: nil)
    }
    
    func changeSaveButtonStyle(withStatus status: ARFrame.WorldMappingStatus) {
        switch status {
        case .notAvailable, .limited:
            saveButton.backgroundColor = UIColor.gray
        case .extending, .mapped:
            saveButton.backgroundColor = UIColor.white
        }
    }
    
    private func updateWorldMappingStatusInfoLabel(forframe frame: ARFrame) {
        changeSaveButtonStyle(withStatus: frame.worldMappingStatus)
        
        switch frame.worldMappingStatus {
        case .notAvailable:
            worldMappingStateLabel.text = "Mapping status: notAvailable"
        case .limited:
            worldMappingStateLabel.text = "Mapping status: limited"
        case .extending:
            worldMappingStateLabel.text = "Mapping status: extending"
        case .mapped:
            worldMappingStateLabel.text = "Mapping status: mapped"
        }
    }
    
    private func updateTrackingStatusLabel(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            // "Tracking unavailable."
            print("-------Tracking state notAvailable")
            trackingStateLabel.text = "Tracking state notAvailable"
            preparingDrawingAreaView.isHidden = false
        case .limited(.initializing):
            // "Initializing AR session."
            trackingStateLabel.text = "Tracking state limited(initializing)"
            preparingDrawingAreaView.isHidden = false
        case .limited(.relocalizing):
            // Recovering: Move your phone around the area shown in the image
            if isLoadingSavedWorldMap{
                preparingDrawingAreaLabel.text = "Move your device to the location shown in the image."
            } else {
                
            }
            trackingStateLabel.text = "Tracking state limited(relocalizing)"
            preparingDrawingAreaView.isHidden = false
        case .limited(.excessiveMotion):
            // "Tracking limited - Move the device more slowly."
            trackingStateLabel.text = "Tracking state limited(excessiveMotion)"
            preparingDrawingAreaView.isHidden = false
        case .limited(.insufficientFeatures):
            // Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions.
            trackingStateLabel.text = "Tracking state limited(insufficientFeatures)"
            preparingDrawingAreaView.isHidden = false
        case .normal:
            if isLoadingSavedWorldMap {
                isLoadingSavedWorldMap = false
                showAllUI()
                removeScreenShotFromView()
            }
            print("Tracking state normal")
            trackingStateLabel.text = "Tracking state normal"
            preparingDrawingAreaView.isHidden = true
        }
    }
    
    // MARK:- ARSessionObserver Protocols
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let currentFrame = session.currentFrame else { return }
        updateWorldMappingStatusInfoLabel(forframe: currentFrame)
        updateTrackingStatusLabel(forCamera: camera)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("*****Session was interrupted*****")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("*****Session interruption ended*****")
        // "Resuming session — move to where you were when the session was interrupted."
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // TODO:- Handle the different types of error
        print("*****Session did fail with Error: \(error.localizedDescription)*****")
    }

}

// MARK:- ARSessionDelegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        updateWorldMappingStatusInfoLabel(forframe: frame)
        
        // Draw the spheres
        guard let currentStrokeAnchorID = strokeAnchorIDs.last else { return }
        let currentStrokeAnchor = anchorForID(currentStrokeAnchorID)
        if currentFingerPosition != nil && currentStrokeAnchor != nil {
            guard let currentPointPosition = getPosition(ofPoint: currentFingerPosition!, atDistanceFromCamera: 0.2, inView: sceneView) else { return }
            
            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.00026 {
                    createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                    // Draw spheres between the currentPoint and previous point if they are further than the specified distance (Otherwise fast movement will make the line blocky)
                    // TODO: The spacing should depend on the brush size
                    let positions = getPositionsOnLineBetween(point1: previousPoint, andPoint2: currentPointPosition, withSpacing: 0.00025)
                    createSphereAndInsert(atPositions: positions, andAddToStrokeAnchor: currentStrokeAnchor!)
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

// MARK:- ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This is only used when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            currentStrokeAnchorNode = node
            strokeAnchorIDs.append(strokeAnchor.identifier)
            for sphereLocation in strokeAnchor.sphereLocations {
                createSphereAndInsert(atPosition: SCNVector3Make(sphereLocation[0], sphereLocation[1], sphereLocation[2]), andAddToStrokeAnchor: strokeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the anchorID from the strokes array
        print("Anchor removed")
        strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
    }
}
