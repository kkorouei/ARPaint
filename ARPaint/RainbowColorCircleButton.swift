//
//  RainbowCircleButton.swift
//  ARPaint
//
//  Created by Koushan Korouei on 04/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

class RainbowColorCircleButton: UIButton {

    var circle: CircleView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupButton()
    }
    
    override func prepareForInterfaceBuilder() {
        setupButton()
    }
    
    func setupButton() {
        self.setTitle("", for: .normal)
        circle = CircleView(frame: self.bounds)
        circle.drawRainbowColorCircle()
        addSubview(circle)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO:- Change the color of the button on touch
        super.touchesBegan(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO:- Change the color of the button on touch
        super.touchesEnded(touches, with: event)
    }

}
