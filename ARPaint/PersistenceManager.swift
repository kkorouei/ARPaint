//
//  PersistenceManager.swift
//  ARPaint
//
//  Created by Koushan Korouei on 25/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import Foundation
import ARKit

func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
    let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
    try data.write(to: url)
}

func loadWorldMap(from url: URL) throws -> ARWorldMap {
    let mapData = try Data(contentsOf: url)
    guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else {
            throw ARError(.invalidWorldMap)
    }
    return worldMap
}

func saveCurrentWorldMap(forSceneView sceneView: ARSCNView, completion: @escaping (Bool, String) ->Void ) {
    sceneView.session.getCurrentWorldMap { (worldMap, error) in
        guard let map = worldMap else {
            let message = ("Can't get world map: \(error!.localizedDescription)")
            completion(false, message)
            return
        }
        // Save the map
        let pathToSave = getDocumentsDirectory().appendingPathComponent("test")
        do {
            try writeWorldMap(map, to: pathToSave)
            let message = ("Map saved succesfully")
            completion(true, message)
        } catch {
            let message = ("Could not save the map. \(error.localizedDescription)")
            completion(false, message)
        }
    }
}
