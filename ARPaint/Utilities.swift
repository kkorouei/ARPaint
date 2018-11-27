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

// Gets the position of the point x units in front of the camera
func getPositionInFront(OfCamera camera: ARCamera?, byAmount amount: Float) -> float4x4? {
    guard let cameraTransform = camera?.transform else { return nil }
    var translation = matrix_identity_float4x4
    translation.columns.3.x = 0
    translation.columns.3.y = 0
    translation.columns.3.z = amount
    let currentPointTransform = matrix_multiply(cameraTransform, translation)
    return currentPointTransform
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

extension CGImagePropertyOrientation {
    /// Preferred image presentation orientation respecting the native sensor orientation of iOS device camera.
    init(cameraOrientation: UIDeviceOrientation) {
        switch cameraOrientation {
        case .portrait:
            self = .right
        case .portraitUpsideDown:
            self = .left
        case .landscapeLeft:
            self = .up
        case .landscapeRight:
            self = .down
        default:
            self = .right
        }
    }
}
