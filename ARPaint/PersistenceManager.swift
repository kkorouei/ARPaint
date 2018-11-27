//
//  PersistenceManager.swift
//  ARPaint
//
//  Created by Koushan Korouei on 25/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import Foundation
import ARKit
import CoreData

//func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
//    let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
//    try data.write(to: url)
//}

func loadWorldMap(from drawing: Drawing) throws -> ARWorldMap {
    let mapData = drawing.worldMap as Data
    guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else {
            throw ARError(.invalidWorldMap)
    }
    return worldMap
}

func getManagedObjectContext() -> NSManagedObjectContext {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    return appDelegate.persistentContainer.viewContext
}

func fetchAllDrawingsFromCoreData() -> [Drawing] {
    let managedObjectContext = getManagedObjectContext()
    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Drawing")

    do {
        let results = try managedObjectContext.fetch(fetchRequest) as! [Drawing]
        print("Results fetched successfully. count: \(results.count)")
        return results
    } catch  {
        print("Error performing fetch request. \(error.localizedDescription)")
        return []
    }
}

func saveCurrentWorldMapToCoreData(forSceneView sceneView: ARSCNView, completion: @escaping (Bool, String) ->Void ) {
    sceneView.session.getCurrentWorldMap { (worldMap, error) in
        guard let map = worldMap else {
            let message = ("Can't get world map: \(error!.localizedDescription)")
            completion(false, message)
            return
        }
        let managedObjectContext = getManagedObjectContext()
        
        let drawing = Drawing(context: managedObjectContext)
        do {
            // Convert the ARWorldMap to data format
            let worldMapData = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true) as NSData
            drawing.worldMap = worldMapData
        } catch {
            let message = ("Could not convert the worldMap into data. \(error.localizedDescription)")
            completion(false, message)
        }
        
        guard let screenShot = takeSnapShot(ofFrame: sceneView.session.currentFrame) as NSData? else {
            let message = "Could not convert screenshot to data"
            completion(false, message)
            return
        }
        drawing.screenShot = screenShot
        drawing.dateCreated = Date() as NSDate
        
        do {
            // Save
            try managedObjectContext.save()
            let message = ("Map saved succesfully")
            completion(true, message)
        } catch {
            let message = ("Could not save the map. \(error.localizedDescription)")
            completion(false, message)
        }
    }
}

//func saveCurrentWorldMap(forSceneView sceneView: ARSCNView, completion: @escaping (Bool, String) ->Void ) {
//    sceneView.session.getCurrentWorldMap { (worldMap, error) in
//        guard let map = worldMap else {
//            let message = ("Can't get world map: \(error!.localizedDescription)")
//            completion(false, message)
//            return
//        }
//        // Save the map
//        let pathToSave = getDocumentsDirectory().appendingPathComponent("test")
//        do {
//            try writeWorldMap(map, to: pathToSave)
//            let message = ("Map saved succesfully")
//            completion(true, message)
//        } catch {
//            let message = ("Could not save the map. \(error.localizedDescription)")
//            completion(false, message)
//        }
//    }
//}