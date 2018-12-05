//
//  SphereNodes.swift
//  ARPaint
//
//  Created by Koushan Korouei on 05/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import SceneKit

enum StrokeColor: String {
    case white = "white"
    case green = "green"
    case red = "red"
}

func getReferenceSphereNode(forStrokeColor color: StrokeColor) -> SCNNode {
    switch color {
    case .white:
        return whiteSphereNode
    case .green:
        return greenSphereNode
    case .red:
        return redSphereNode
    }
}

var whiteSphereNode: SCNNode = {
    let sphere = SCNSphere(radius: 0.005)
    sphere.firstMaterial?.diffuse.contents = UIColor.white
    return SCNNode(geometry: sphere)
}()

var greenSphereNode: SCNNode = {
    let sphere = SCNSphere(radius: 0.005)
    sphere.firstMaterial?.diffuse.contents = UIColor.green
    return SCNNode(geometry: sphere)
}()

var redSphereNode: SCNNode = {
    let sphere = SCNSphere(radius: 0.005)
    sphere.firstMaterial?.diffuse.contents = UIColor.red
    return SCNNode(geometry: sphere)
}()


