//
//  CGImagePropertyOrientation+Extensions.swift
//  ARPaint
//
//  Created by Koushan Korouei on 29/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

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
