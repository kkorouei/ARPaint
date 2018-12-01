//
//  Utilities.swift
//  ARPaint
//
//  Created by Koushan Korouei on 25/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit
import ARKit

func getDocumentsDirectory() -> URL {
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                    .userDomainMask,
                                                    true) as [String]
    return URL(fileURLWithPath: paths.first!)
}

func getCameraPosition(in view: ARSCNView) -> SCNVector3? {
    guard let lastFrame = view.session.currentFrame else {
        return nil
    }
    let position = lastFrame.camera.transform * float4(x: 0, y: 0, z: 0, w: 1)
    let camera: SCNVector3 = SCNVector3(position.x, position.y, position.z)
    
    return camera
}

// Gets the real world position of the touch point x distance away from the camera
func getPosition(ofPoint point: CGPoint, atDistanceFromCamera distance: Float, inView view: ARSCNView) -> SCNVector3? {
    guard let cameraPosition = getCameraPosition(in: view) else { return nil}
    let directionOfPoint = getDirection(for: point, in: view).normalized()
    return (directionOfPoint * distance) + cameraPosition

}

// Takes the coordinates of the 2D point and converts it to a vector in the real world
func getDirection(for point: CGPoint, in view: SCNView) -> SCNVector3 {
    let farPoint  = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 1))
    let nearPoint = view.unprojectPoint(SCNVector3Make(Float(point.x), Float(point.y), 0))
    
    return SCNVector3Make(farPoint.x - nearPoint.x, farPoint.y - nearPoint.y, farPoint.z - nearPoint.z)
}

// MARK:- Drawing
// Gets the positions of the points on the line between point1 and point2 with the given spacing
func getPositionsOnLineBetween(point1: SCNVector3, andPoint2 point2: SCNVector3, withSpacing spacing: Float) -> [SCNVector3]{
    var positions: [SCNVector3] = []
    // Calculate the distance between previous point and current point
    let distance = point1.distance(vector: point2)
//    let distanceBetweenEachCircle: Float = 0.00025
    let numberOfCirclesToCreate = Int(distance / spacing)
    
    // https://math.stackexchange.com/a/83419
    // Begin by creating a vector BA by subtracting A from B (A = previousPoint, B = currentPoint)
    let vectorBA = point2 - point1
    // Normalize vector BA by dividng it by it's length
    let vectorBANormalized = vectorBA.normalized()
    // This new vector can now be scaled and added to A to find the point at the specified distance
    for i in 0...((numberOfCirclesToCreate > 1) ? (numberOfCirclesToCreate - 1) : numberOfCirclesToCreate) {
        let position = point1 + (vectorBANormalized * (Float(i) * spacing))
        positions.append(position)
    }
    return positions
}

// MARK:- SnapShots
func takeSnapShot(ofFrame frame: ARFrame?) -> Data?{
    guard let frame = frame else {
        return nil
    }
    let image = CIImage(cvPixelBuffer: frame.capturedImage)
    let orientation = CGImagePropertyOrientation(cameraOrientation: UIDevice.current.orientation)
    
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let data = context.jpegRepresentation(of: image.oriented(orientation),
                                                colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
        else { return nil}
    return data
}

func takeSnapShot(ofSceneview sceneView: ARSCNView?) -> Data?{
    guard let sceneView = sceneView else {
        return nil
    }
    let image = CIImage(image: sceneView.snapshot())!
    
    let context = CIContext(options: [.useSoftwareRenderer: false])
    guard let data = context.jpegRepresentation(of: image,
                                                colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
        else { return nil}
    return data
}
