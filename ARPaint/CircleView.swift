//
//  CircleView.swift
//  ARPaint
//
//  Created by Koushan Korouei on 03/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//

import UIKit

class CircleView: UIView {
    
    let shapeLayer = CAShapeLayer()
    var height: CGFloat {
        return self.bounds.height
    }
    var width: CGFloat {
        return self.bounds.width
    }
    var radius: Float = 5 {
        didSet {
            change(radius: radius)
        }
    }
    var color: UIColor = .white {
        didSet {
            shapeLayer.fillColor = color.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    override func draw(_ rect: CGRect) {
    }
    
    private func setupView() {
        self.backgroundColor = UIColor.clear
        drawCircle()
    }
    
    private func drawCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: width / 2,y: height / 2), radius: CGFloat(width / 2), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        shapeLayer.path = circlePath.cgPath
        
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = 3.0
        
        layer.addSublayer(shapeLayer)
    }
    
    private func change(radius: Float) {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: width / 2,y: height / 2), radius: CGFloat(radius), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        shapeLayer.path = circlePath.cgPath
    }

}
