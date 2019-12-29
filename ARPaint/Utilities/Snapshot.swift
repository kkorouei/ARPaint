//
//  Snapshot.swift
//  ARPaint
//
//  Created by Koushan Korouei on 29/12/2019.
//  Copyright © 2019 Koushan Korouei. All rights reserved.
//

import ARKit

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
