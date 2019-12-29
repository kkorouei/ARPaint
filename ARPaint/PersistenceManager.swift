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

class PersistenceManager {

    static let shared = PersistenceManager()
    private var managedObjectContext: NSManagedObjectContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.persistentContainer.viewContext
    }

    private init() {}

    func loadWorldMap(from drawing: Drawing) throws -> ARWorldMap {
        let mapData = drawing.worldMap as Data
        guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
            else {
                throw ARError(.invalidWorldMap)
        }
        return worldMap
    }

    func fetchAllDrawingsFromCoreData() -> [Drawing] {
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

    func getCurrentWorldMapAndScreenShot(forSceneView sceneView: ARSCNView, completion: @escaping (_ wordlMap: ARWorldMap?, _ screenShot: NSData?, _ errorMessage: String?) -> Void) {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            let message: String
            guard let worldMap = worldMap  else {
                message = ("Can't get world map: \(error!.localizedDescription)")
                completion(nil, nil, message)
                return
            }
            guard let screenShot = takeSnapShot(ofFrame: sceneView.session.currentFrame) as NSData? else {
                message = "Could not convert screenshot to data"
                completion(nil, nil, message)
                return
            }
            completion(worldMap, screenShot, nil)
        }
    }

    func saveDrawingToCoreData(withWorldMap worldMap: ARWorldMap, name: String, screenShot: NSData, completion: @escaping (Bool, String) ->Void ) {

        let drawing = Drawing(context: managedObjectContext)
        do {
            // Convert the ARWorldMap to data format
            let worldMapData = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true) as NSData
            drawing.worldMap = worldMapData
        } catch {
            let message = ("Could not convert the worldMap into data. \(error.localizedDescription)")
            completion(false, message)
        }

        drawing.screenShot = screenShot
        drawing.dateCreated = Date() as NSDate
        drawing.name = name

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

    func deleteDrawingFromCoreData(drawing: Drawing, completion: (Bool, String) -> Void ) {

        managedObjectContext.delete(drawing)

        do {
            try managedObjectContext.save()
            let message = "Succesffully deleted drawing from coreData"
            completion(true, message)
        } catch {
            let message = ("Could not save to Core Data After deleting. \(error)")
            completion(false, message)
        }
    }
}
