//
//  TrackingStateView.swift
//  ARPaint
//
//  Created by Koushan Korouei on 29/12/2019.
//  Copyright © 2019 Koushan Korouei. All rights reserved.
//

import UIKit
import ARKit

class TrackingStateView: UIView {

    @IBOutlet var view: UIView!
    @IBOutlet weak var trackingStateImageView: UIImageView!
    @IBOutlet weak var trackingStateTitleLabel: UILabel!
    @IBOutlet weak var trackingStateMessageLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("TrackingStateView", owner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // Setup trackingStateImageView tint color
        trackingStateImageView.tintColor = UIColor.white
    }

    // Updates the view depending on the tracking state
    func update(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            // "Tracking unavailable."
            isHidden = true
            break
        case .limited(.initializing):
            isHidden = false
            trackingStateImageView.image = UIImage(named: "move-phone")
            trackingStateTitleLabel.text = "Detecting world"
            trackingStateMessageLabel.text = "Move your device around slowly"
            addPhoneMovingAnimation()
        case .limited(.relocalizing):
            isHidden = true
            removePhoneMovingAnimation()
        case .limited(.excessiveMotion):
            isHidden = false
            trackingStateImageView.image = UIImage(named: "exclamation")
            trackingStateTitleLabel.text = "Too much movement"
            trackingStateMessageLabel.text = "Move your device more slowly"
            removePhoneMovingAnimation()
        case .limited(.insufficientFeatures):
            isHidden = false
            trackingStateImageView.image = UIImage(named: "light-bulb")
            trackingStateTitleLabel.text = "Not enough detail"
            trackingStateMessageLabel.text = "Move around or find a better lit place"
            removePhoneMovingAnimation()
        case .normal:
            isHidden = true
            removePhoneMovingAnimation()
            break
        }
    }

    // MARK:- Phone icon animation

    private func addPhoneMovingAnimation() {
        self.trackingStateImageView.frame.origin.x -= 50
        UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.trackingStateImageView.frame.origin.x += 100
        })
    }

    private func removePhoneMovingAnimation() {
        trackingStateImageView.layer.removeAllAnimations()
        // Reset the imageView position
        trackingStateImageView.frame.origin.x = 90
    }
}
