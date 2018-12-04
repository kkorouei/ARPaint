//
//  ColoredCircleButton.swift
//  ARPaint
//
//  Created by Koushan Korouei on 03/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

@IBDesignable
class SingleColorCircleButton: UIButton {
    
    var circle: CircleView!
    
    @IBInspectable
    var circleColor: UIColor = .blue {
        didSet {
            circle.color = circleColor
        }
    }
    
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
        circle.drawSingleColorCircle()
        circle.color = circleColor
        addSubview(circle)

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // TODO:- Make the button color darker 
        // Make the button white when touched
        super.touchesBegan(touches, with: event)
        circle.color = .white
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        circle.color = circleColor
    }

}
