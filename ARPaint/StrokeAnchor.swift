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

class StrokeAnchor: ARAnchor {
    
    let imageData: Data
    var sphereLocations: [[Float]] = []
    let dateCreated: TimeInterval
    
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
        self.init(name: name, imageData: data, transform: x.simdTransform)
    }
    
    init(name: String, imageData: Data, transform: float4x4) {
        self.imageData = imageData
        self.dateCreated = NSDate().timeIntervalSince1970
        super.init(name: name, transform: transform)
    }
    
    required init(anchor: ARAnchor) {
        self.imageData = (anchor as! StrokeAnchor).imageData
        self.sphereLocations = (anchor as! StrokeAnchor).sphereLocations
        self.dateCreated = (anchor as! StrokeAnchor).dateCreated
        super.init(anchor: anchor)
    }
    
    override class var supportsSecureCoding: Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        if let snapshot = aDecoder.decodeObject(forKey: "snapshot") as? Data,
            let sphereLocations = aDecoder.decodeObject(forKey: "array") as? [[Float]],
            let dateCreated = aDecoder.decodeObject(forKey: "dateCreated") as? NSNumber{
            self.imageData = snapshot
            self.sphereLocations = sphereLocations
            self.dateCreated = dateCreated.doubleValue
        } else {
            return nil
        }
        
        super.init(coder: aDecoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(imageData, forKey: "snapshot")
        aCoder.encode(sphereLocations, forKey: "array")
        aCoder.encode(NSNumber(value: dateCreated), forKey: "dateCreated")
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
