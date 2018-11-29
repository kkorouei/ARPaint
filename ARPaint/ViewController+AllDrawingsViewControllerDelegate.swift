//
//  ViewController+AllDrawingsViewControllerDelegate.swift
//  ARPaint
//
//  Created by Koushan Korouei on 29/11/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

extension ViewController: AllDrawingsViewControllerDelegate {
    func allDrawingsViewController(_ controller: AllDrawingsViewController, didSelectDrawing drawing: Drawing) {
        let screenShot = UIImage(data: drawing.screenShot as Data)
        dismiss(animated: true, completion: nil)
        do {
            let worldMap = try loadWorldMap(from: drawing)
            reStartSession(withWorldMap: worldMap)
            print("Map successfuly loaded")
            
            addScreenShotToView(screenShot: screenShot, fullSize: true)
            
        } catch {
            print("Could not load worldMap. Error: \(error)")
        }
    }
    
    func allDrawingsViewControllerDidPressCancel(_ controller: AllDrawingsViewController) {
        dismiss(animated: true, completion: nil)
        sceneView.session.run(sceneView.session.configuration!)
        
        // FIX:- When the user has loaded a preivous drawing, presses Undo/delete, then presses load and then cancels,
        // the previous drawing gets relocalized, this is becuase the previous session is restarted. Kapich?
        // This is probably becuase its using the old world map since the new one is not saved
        // The best way to fix this is to probably make the allDrawingsViewController into a view and just add it as a subview.
        // No more pausing og the session will occur
    }
    
    func addScreenShotToView(screenShot: UIImage?, fullSize: Bool) {
        if fullSize {
            // Create an imageView and overlay it onto the screen
            screenShotOverlayImageView = UIImageView(frame: UIScreen.main.bounds)
            screenShotOverlayImageView!.contentMode = .scaleAspectFit
            screenShotOverlayImageView!.layer.opacity = 0.5
        } else {
            // Create a small thumbNail imageView and add it to the top left corner
            screenShotOverlayImageView = UIImageView(frame: CGRect(x: 20,
                                                                   y: 130,
                                                                   width: UIScreen.main.bounds.width / CGFloat(3),
                                                                   height: UIScreen.main.bounds.height / CGFloat(3)))
            screenShotOverlayImageView!.contentMode = .scaleAspectFit
        }
        screenShotOverlayImageView!.image = screenShot
        sceneView.addSubview(screenShotOverlayImageView!)
    }
}
