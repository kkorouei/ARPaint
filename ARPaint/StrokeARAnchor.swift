//
//  StrokeARAnchor.swift
//  ARPaint
//
//  Created by Koushan Korouei on 22/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//
// Code used from Apple ARPersistence sample project

import UIKit
import ARKit

class StrokeARAnchor: ARAnchor {
    
    let imageData: Data
    var sphereLocations: [[Float]] = []
    
    convenience init?(name: String, capturing view: ARSCNView) {
        guard let frame = view.session.currentFrame
            else { return nil }
        
        let image = CIImage(cvPixelBuffer: frame.capturedImage)
        let orientation = CGImagePropertyOrientation(cameraOrientation: UIDevice.current.orientation)
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let data = context.jpegRepresentation(of: image.oriented(orientation),
                                                    colorSpace: CGColorSpaceCreateDeviceRGB(),
                                                    options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.7])
            else { return nil }
        // This anchor position should be zero (For now)
        let zeroPosition = SCNVector3Make(0, 0, 0)
        let x = SCNNode()
        x.position = zeroPosition
        self.init(name: name, imageData: data, transform: x.simdTransform)//frame.camera.transform)
    }
    
    init(name: String, imageData: Data, transform: float4x4) {
        self.imageData = imageData
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        self.imageData = (anchor as! StrokeARAnchor).imageData
        self.sphereLocations = (anchor as! StrokeARAnchor).sphereLocations
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let snapshot = aDecoder.decodeObject(forKey: "snapshot") as? Data,
            let sphereLocations = aDecoder.decodeObject(forKey: "array") as? [[Float]]{
            self.imageData = snapshot
            self.sphereLocations = sphereLocations
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
        aCoder.encode(sphereLocations, forKey: "array")
    }
    
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

extension ARWorldMap {
    var snapshotAnchor: StrokeARAnchor? {
        return anchors.compactMap { $0 as? StrokeARAnchor }.first
    }
}
