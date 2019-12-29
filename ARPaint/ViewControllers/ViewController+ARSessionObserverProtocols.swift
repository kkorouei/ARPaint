//
//  ViewController+ARSessionObserverProtocol.swift
//  ARPaint
//
//  Created by Koushan Korouei on 09/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit
import ARKit

extension ViewController {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let currentFrame = session.currentFrame else { return }
        updateDebugWorldMappingStatusInfoLabel(forframe: currentFrame)
        updateDebugTrackingStatusLabel(forCamera: camera)
        trackingStateView.update(forCamera: camera)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        trackingStateView.isHidden = true
        
        let messageLabel = UILabel()
        messageLabel.backgroundColor = UIColor.white
        messageLabel.layer.cornerRadius = 7
        messageLabel.layer.masksToBounds = true
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.lineBreakMode = .byWordWrapping
        messageLabel.textAlignment = .center
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.sceneView.addSubview(messageLabel)
        // Constraints
        let horizontalConstraint = NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: sceneView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: sceneView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 320)
        let heightConstraint = NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 60)
        view.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        
        if (error as NSError).code == 103 {
            // The user has denied your app permission to use the device camera.
            messageLabel.text = "Camera access required \nPlease allow access in settings"
            messageLabel.numberOfLines = 2
            hideAllUI(includingResetButton: true)
        } else {
            // Either worldTrackingFailed, sensorUnavailable, sensorFailed or unsupportedConfiguration
            messageLabel.text = error.localizedDescription
            messageLabel.numberOfLines = 0
        }
        // TODO:- Handle the different types of error
        print("*****Session did fail with Error: \(error.localizedDescription)*****")
    }

}
