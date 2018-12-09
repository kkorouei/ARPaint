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
            
            addScreenShotToView(screenShot: screenShot, fullSize: false)
            
        } catch {
            print("Could not load worldMap. Error: \(error)")
        }
    }
    
    func allDrawingsViewControllerDidPressCancel(_ controller: AllDrawingsViewController) {
        dismiss(animated: true, completion: nil)
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
                                                                   y: 20,
                                                                   width: UIScreen.main.bounds.width / CGFloat(3),
                                                                   height: UIScreen.main.bounds.height / CGFloat(3)))
            screenShotOverlayImageView!.contentMode = .scaleAspectFill
            screenShotOverlayImageView?.layer.cornerRadius = 7
            screenShotOverlayImageView?.clipsToBounds = true
        }
        screenShotOverlayImageView!.image = screenShot
        sceneView.addSubview(screenShotOverlayImageView!)
    }
    
    func removeScreenShotFromView() {
        self.screenShotOverlayImageView?.removeFromSuperview()
        self.screenShotOverlayImageView = nil
        // Haptick feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
