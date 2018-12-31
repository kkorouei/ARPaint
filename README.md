# ARPaint

Augmented Reality drawing app that lets users save and load their drawings in the real world.

[![Everything Is AWESOME](https://i.imgur.com/gZzeB3s.png)](https://www.youtube.com/watch?v=OZCFj-rOpYw "AR Paint")

# A brief explanation about saving and loading world maps

The worldMap, as well as a snapshot of the current view is returned using the following method:

``` swift
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
```

The worldMap and snapshot are then saved inside a CoreData Entity named "Drawing".

The worldMap is later retrieved from the Drawing entity using the following method:

``` swift
func loadWorldMap(from drawing: Drawing) throws -> ARWorldMap {
    let mapData = drawing.worldMap as Data
    guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: mapData)
        else {
            throw ARError(.invalidWorldMap)
    }
    return worldMap
}
```

To relocalize to the saved map, we create a new session configuration, set the inialWorldMap property to the map we just loaded, and then run the session:

``` swift
let configuration = ARWorldTrackingConfiguration()
configuration.initialWorldMap = worldMap
sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
```

The snapshot of where the map was saved is shown in the top left corner of the screen so the user knows where to point their device towards. If the map is relocalized successfully, the tracking state changes to ARCamera.TrackingState.normal and all the ARAnchors that were saved inside the worldMap are added to the scene. 

![alt-text](https://github.com/kkorouei/ARPaint/blob/22d88d063bcf5f494fbdffe6193edb9dda7c4b5a/load.gif)

