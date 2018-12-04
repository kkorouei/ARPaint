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
        // TOD:- Make the button color darker
        // Make the button white when touched
        circle.color = .white
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        circle.color = circleColor
    }

}
