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
    @IBOutlet weak var debugTrackingStateLabel: UILabel!
    @IBOutlet weak var debugWorldMappingStateLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var relocalizingLabelView: UIVisualEffectView!
    @IBOutlet weak var additionalButtonsView: UIView!
    @IBOutlet weak var BrushColorSelectionView: UIView!
    @IBOutlet weak var saveLoadSelectionView: UIView!
    @IBOutlet weak var menuButtonsView: UIView!
    @IBOutlet weak var menuButtonsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resetView: UIView!
    @IBOutlet weak var saveErrorLabel: UILabel!
    // Tracking State View
    @IBOutlet weak var trackingStateView: UIView!
    @IBOutlet weak var trackingStateImageView: UIImageView!
    @IBOutlet weak var trackingStateTitleLabel: UILabel!
    @IBOutlet weak var trackingStateMessageLabel: UILabel!
    
    var previousPoint: SCNVector3?
    var currentFingerPosition: CGPoint?
    
    var screenShotOverlayImageView: UIImageView?
    
    var whiteBallCount = 0
    var sphereCountLabel: UILabel!
    
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    var currentStrokeColor: StrokeColor = .white
    
    var isLoadingSavedWorldMap = false

    let sphereNodesManager = SphereNodesManager()
    
    
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

        // Add sphere count label
        sphereCountLabel = UILabel(frame: CGRect(x: 20, y: 20, width: 100, height: 40))
        sphereCountLabel.textColor = UIColor.orange
        sphereCountLabel.isHidden = true
        sceneView.addSubview(sphereCountLabel)
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        
        // Add long press gesture to undo button for deleting all anchors
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressUndoButton))
        undoButton.addGestureRecognizer(longPressGesture)

        // Setup trackingStateImageView tint color
        trackingStateImageView.tintColor = UIColor.white
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // Make the menuButtonsView height taller for iPhoneX,XS,XR
        let menuButtonsViewHeight: CGFloat = 70
        let bottomPadding = view.safeAreaInsets.bottom
        menuButtonsViewHeightConstraint.constant = menuButtonsViewHeight + bottomPadding
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
    
    func hideAllUI(includingResetButton: Bool) {
        DispatchQueue.main.async {
            self.menuButtonsView.isHidden = true
            self.additionalButtonsView.isHidden = true
            self.saveErrorLabel.isHidden = true
            if includingResetButton {
                self.resetView.isHidden = true
            }
        }
    }
    
    func showAllUI() {
        DispatchQueue.main.async {
            self.menuButtonsView.isHidden = false
            self.resetView.isHidden = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showAllDrawingsVC" {
            let navigationController = segue.destination as! UINavigationController
            let drawingsViewController = navigationController.viewControllers[0] as! AllDrawingsViewController
            drawingsViewController.delegate = self
            let fetchedDrawings =  PersistenceManager.shared.fetchAllDrawingsFromCoreData()
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
            hideAllUI(includingResetButton: false)
        } else {
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
        let referenceSphereNode = sphereNodesManager.getReferenceSphereNode(forStrokeColor: strokeAnchor.color)
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
        // Do not let the user draw if the world map is relocalizing
        if isLoadingSavedWorldMap {
            return
        }
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
    
    @IBAction func resetButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
        reStartSession(withWorldMap: nil)
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
                saveErrorLabel.isHidden = true
            } else {
                BrushColorSelectionView.isHidden = true
                saveLoadSelectionView.isHidden = false
            }
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        // TODO:- Clean up and refactor
        guard let currentFrame = sceneView.session.currentFrame else { return }
        switch currentFrame.worldMappingStatus {
        case .notAvailable, .limited:
            saveErrorLabel.isHidden = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.saveErrorLabel.isHidden = true
            }
        case .extending, .mapped:
            additionalButtonsView.isHidden = true
            hideAllUI(includingResetButton: true)
            
            PersistenceManager.shared.getCurrentWorldMapAndScreenShot(forSceneView: sceneView) { (worldMap, screenShot, errorMessage) in
                if errorMessage != nil {
                    // Some error happened
                    self.showSimpleAlert(withTitle: "Error", andMessage: errorMessage, completionHandler: {
                        self.showAllUI()
                    })
                    return
                }
                
                let alertController = UIAlertController(title: "Save", message: "Enter a name for the saved scenes", preferredStyle: .alert)
                let saveAction = UIAlertAction(title: "Save", style: .default, handler: { (_) in
                    let nameTextField = alertController.textFields![0]
                    let name = (nameTextField.text ?? "").isEmpty ? "My Drawing" : nameTextField.text!
                    PersistenceManager.shared.saveDrawingToCoreData(withWorldMap: worldMap!, name: name, screenShot: screenShot!, completion: { (success, message) in
                        if success {
                            self.showSimpleAlert(withTitle: "Scene Successfully Saved", andMessage: nil, completionHandler: {
                                self.showAllUI()
                            })
                        } else {
                            self.showSimpleAlert(withTitle: "Error", andMessage: "Unable To Save Scene", completionHandler: {
                                self.showAllUI()
                            })
                        }
                        print(message)
                    })
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
                    self.showAllUI()
                })
                alertController.addTextField { (textField) in
                    textField.placeholder = "My Drawing"
                }
                alertController.addAction(saveAction)
                alertController.addAction(cancelAction)
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func loadButtonPressed(_ sender: UIButton) {
        performSegue(withIdentifier: "showAllDrawingsVC", sender: self)
        additionalButtonsView.isHidden = true
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
        saveErrorLabel.isHidden = true
        let image = sceneView.snapshot()
        
        let screenShotNavigationController = storyboard?.instantiateViewController(withIdentifier: "screenShotNav") as! UINavigationController
        let screenShotViewController = screenShotNavigationController.viewControllers[0] as! ScreenShotViewController
        screenShotViewController.screenShotImage = image
        screenShotNavigationController.modalPresentationStyle = .overCurrentContext
        present(screenShotNavigationController, animated: true, completion: nil)
    }
    
    @IBAction func changeColorButtonPressed(_ sender: UIButton) {
        saveErrorLabel.isHidden = true
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
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        additionalButtonsView.isHidden = true
        saveErrorLabel.isHidden = true
        sortStrokeAnchorIDsInOrderOfDateCreated()
        
        guard let currentStrokeAnchorID = strokeAnchorIDs.last, let curentStrokeAnchor = anchorForID(currentStrokeAnchorID) else {
            print("No stroke to remove")
            return
        }
        sceneView.session.remove(anchor: curentStrokeAnchor)

        // add this?
        currentStrokeAnchorNode = nil
    }
    
    // Brush Colors changed
    // TODO: Make them into one action outlet
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
    
    func changeSaveButtonStyle(withStatus status: ARFrame.WorldMappingStatus) {
        switch status {
        case .notAvailable, .limited:
            saveButton.backgroundColor = UIColor.gray
        case .extending, .mapped:
            saveButton.backgroundColor = UIColor.white
        }
    }
    
    func updateDebugWorldMappingStatusInfoLabel(forframe frame: ARFrame) {
        changeSaveButtonStyle(withStatus: frame.worldMappingStatus)
        
        switch frame.worldMappingStatus {
        case .notAvailable:
            debugWorldMappingStateLabel.text = "Mapping status: notAvailable"
        case .limited:
            debugWorldMappingStateLabel.text = "Mapping status: limited"
        case .extending:
            debugWorldMappingStateLabel.text = "Mapping status: extending"
        case .mapped:
            debugWorldMappingStateLabel.text = "Mapping status: mapped"
        }
    }
    
    func updateDebugTrackingStatusLabel(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            // "Tracking unavailable."
            debugTrackingStateLabel.text = "Tracking state notAvailable"
            relocalizingLabelView.isHidden = true
        case .limited(.initializing):
            // "Initializing AR session."
            debugTrackingStateLabel.text = "Tracking state limited(initializing)"
            relocalizingLabelView.isHidden = true
        case .limited(.relocalizing):
            debugTrackingStateLabel.text = "Tracking state limited(relocalizing)"
            relocalizingLabelView.isHidden = false
        case .limited(.excessiveMotion):
            // "Tracking limited - Move the device more slowly."
            debugTrackingStateLabel.text = "Tracking state limited(excessiveMotion)"
            relocalizingLabelView.isHidden = true
        case .limited(.insufficientFeatures):
            // Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions.
            debugTrackingStateLabel.text = "Tracking state limited(insufficientFeatures)"
            relocalizingLabelView.isHidden = true
        case .normal:
            if isLoadingSavedWorldMap {
                isLoadingSavedWorldMap = false
                showAllUI()
                removeScreenShotFromView()
            }
            debugTrackingStateLabel.text = "Tracking state normal"
            relocalizingLabelView.isHidden = true
        }
    }
    
    func changeTrackingStateView(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            // "Tracking unavailable."
            trackingStateView.isHidden = true
            break
        case .limited(.initializing):
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "move-phone")
            trackingStateTitleLabel.text = "Detecting world"
            trackingStateMessageLabel.text = "Move your device around slowly"
            addPhoneMovingAnimation()
        case .limited(.relocalizing):
            trackingStateView.isHidden = true
            debugTrackingStateLabel.text = "Tracking state limited(relocalizing)"
            removePhoneMovingAnimation()
        case .limited(.excessiveMotion):
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "exclamation")
            trackingStateTitleLabel.text = "Too much movement"
            trackingStateMessageLabel.text = "Move your device more slowly"
            removePhoneMovingAnimation()
        case .limited(.insufficientFeatures):
            trackingStateView.isHidden = false
            trackingStateImageView.image = UIImage(named: "light-bulb")
            trackingStateTitleLabel.text = "Not enough detail"
            trackingStateMessageLabel.text = "Move around or find a better lit place"
            removePhoneMovingAnimation()
        case .normal:
            trackingStateView.isHidden = true
            removePhoneMovingAnimation()
            break
        }
    }
    
    // MARK:- Phone icon moving animation
    
    func addPhoneMovingAnimation() {
        self.trackingStateImageView.frame.origin.x -= 50
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.trackingStateImageView.frame.origin.x += 100
        })
    }
    
    func removePhoneMovingAnimation() {
        trackingStateImageView.layer.removeAllAnimations()
        // Reset the imageView position
        trackingStateImageView.frame.origin.x = 90
    }
    
    // MARK:- Alerts
    
    func showSimpleAlert(withTitle title: String, andMessage message: String?, completionHandler: (() -> ())? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .cancel) { (_) in
                completionHandler?()
            }
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

// MARK:- ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        updateDebugWorldMappingStatusInfoLabel(forframe: frame)
        
        // Draw the spheres
        guard let currentStrokeAnchorID = strokeAnchorIDs.last else { return }
        let currentStrokeAnchor = anchorForID(currentStrokeAnchorID)
        if currentFingerPosition != nil && currentStrokeAnchor != nil {
            guard let currentPointPosition = getPosition(ofPoint: currentFingerPosition!, atDistanceFromCamera: 0.2, inView: sceneView) else { return }
            
            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.00104 {
                    createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                    // Draw spheres between the currentPoint and previous point if they are further than the specified distance (Otherwise fast movement will make the line blocky)
                    // TODO: The spacing should depend on the brush size
                    let positions = getPositionsOnLineBetween(point1: previousPoint, andPoint2: currentPointPosition, withSpacing: 0.001)
                    createSphereAndInsert(atPositions: positions, andAddToStrokeAnchor: currentStrokeAnchor!)
                    self.previousPoint = currentPointPosition
                }
            } else {
                createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                self.previousPoint = currentPointPosition
            }
            
            DispatchQueue.main.async {
                self.sphereCountLabel.text = "\(self.whiteBallCount)"
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
