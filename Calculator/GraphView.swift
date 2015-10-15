//
//  GraphView.swift
//  Calculator
//
//  Created by Xing Hui Lu on 10/12/15.
//  Copyright © 2015 Xing Hui Lu. All rights reserved.
//

import UIKit

protocol GraphViewDataSource: class {
    func y(x: CGFloat) -> CGFloat?
}

@IBDesignable
class GraphView: UIView {
    @IBInspectable
    var scale: CGFloat = 1.0 { didSet { setNeedsDisplay() } } // points per unit
    var origin: CGPoint {
        return convertPoint(center, fromView: superview)
    }
    
    var lineWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    var color: UIColor = UIColor.orangeColor() { didSet { setNeedsDisplay() } }
    
    weak var dataSource: GraphViewDataSource?
    
    override func drawRect(rect: CGRect) {
        AxesDrawer(color: color, contentScaleFactor: contentScaleFactor).drawAxesInRect(bounds, origin: origin, pointsPerUnit: scale)
        
        color.set()
        let path = UIBezierPath()
        path.lineWidth = lineWidth
        
        var firstValue = true
        var point = CGPoint()   // prepare the point object
        
        for var i = 0; i <= Int(bounds.size.width * contentScaleFactor) /* converting points to pixels */ ; i++ {
            // set point.x
            point.x = CGFloat(i) / contentScaleFactor    // i.e content scale factor is 2, there is 2 points in 1 pixel
            if let y = dataSource?.y((point.x - origin.x)/scale) {
                // is not normal = infinity, a number, zero
                // and zero
                if !y.isNormal && !y.isZero {
                    firstValue = true
                    continue
                }
                
                // set point.y
                point.y = origin.y - y * scale
                if firstValue {
                    path.moveToPoint(point)
                    firstValue = false
                } else {
                    path.addLineToPoint(point)
                }
            } else {
                firstValue = true
            }
        }
        path.stroke()
    }
}
