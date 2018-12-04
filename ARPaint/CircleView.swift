//
//  CircleView.swift
//  ARPaint
//
//  Created by Koushan Korouei on 03/12/2018.
//  Copyright © 2018 Koushan Korouei. All rights reserved.
//


import UIKit

@IBDesignable
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
    
    override func prepareForInterfaceBuilder() {
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = UIColor.clear
//        drawCircle()
        drawRainbowCircle()
    }
    
    private func drawCircle() {
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: width / 2,y: height / 2),
                                      radius: CGFloat(width / 2),
                                      startAngle: CGFloat(0),
                                      endAngle:CGFloat(Double.pi * 2),
                                      clockwise: true)
    
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

    func drawRainbowCircle() {
        let rainbowColors: [UIColor] = [.red, .blue, .green, .yellow, .black, .white, .orange, .purple, .gray]
        let count: Int = 6
        let gapSize: CGFloat = 0.0
        let segmentAngleSize: CGFloat = (2.0 * CGFloat(Double.pi) - CGFloat(count) * gapSize) / CGFloat(count)
        let center = CGPoint(x: width / 2.0, y: height / 2.0)
        let radius = width / 2

        
        for i in 0 ..< count {
            let start = CGFloat(i) * (segmentAngleSize + gapSize) - CGFloat(Double.pi / 2.0)
            let end = start + segmentAngleSize
            
            
            let arc = UIBezierPath()
            arc.move(to: center)
            let x = center.x +  radius * CGFloat(cos(start));
            let y = center.y + radius * CGFloat(sin(start));
            let next = CGPoint(x: x, y: y)
            arc.addLine(to: next) //go one end of arc
            arc.addArc(withCenter: center,
                       radius: radius,
                       startAngle: start,
                       endAngle: end,
                       clockwise: true) //add the arc
            arc.addLine(to: center)//back to center
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = rainbowColors[i].cgColor
            shapeLayer.path = arc.cgPath
//            shapeLayer.strokeColor = UIColor.white.cgColor
//            shapeLayer.lineWidth = 3.0
            
            layer.addSublayer(shapeLayer)
        }

    }
}
