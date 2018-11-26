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
func getPositionInFront(OfCamera camera: ARCamera?, byAmount amount: Float) -> SCNVector3? {
    guard let cameraTransform = camera?.transform else { return nil }
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
