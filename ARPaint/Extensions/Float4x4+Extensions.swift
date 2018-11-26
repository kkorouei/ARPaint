//
//  Float4x4+Extensions.swift
//  ARPaint
//
//  Created by Koushan Korouei on 26/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import SceneKit

extension float4x4 {
    func convertToSCNVector3() -> SCNVector3 {
        return SCNVector3Make(self.columns.3.x,
                              self.columns.3.y,
                              self.columns.3.z)
    }
}
