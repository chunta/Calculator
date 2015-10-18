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
        get {
            var origin = originRelativeToCenter
            if geometryReady {
                origin.x += center.x
                origin.y += center.y
            }
            return origin
        }
        set {
            var origin = newValue
            if geometryReady {
                origin.x -= center.x
                origin.y -= center.y
            }
            originRelativeToCenter = origin
        }
    }
    
    private var geometryReady = false
    private var originRelativeToCenter: CGPoint = CGPoint() { didSet { setNeedsDisplay() } }
    
    var lineWidth: CGFloat = 1.0 { didSet { setNeedsDisplay() } }
    var color: UIColor = UIColor.orangeColor() { didSet { setNeedsDisplay() } }
    
    weak var dataSource: GraphViewDataSource?
    
    override func drawRect(rect: CGRect) {
        if !geometryReady && originRelativeToCenter != CGPointZero {
            geometryReady = true
        }
        
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
    
    var snapshot: UIView?
    
    func zoom(gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .Began:
            // freezes the view as it is
            snapshot = self.snapshotViewAfterScreenUpdates(false)
            // make it transparent
            snapshot?.alpha = 0.8
            self.addSubview(snapshot!)
        case .Changed:
            let touch = gesture.locationInView(self)
            snapshot!.frame.size.height *= gesture.scale
            snapshot!.frame.size.width *= gesture.scale
            snapshot!.frame.origin.x = snapshot!.frame.origin.x * gesture.scale + (1-gesture.scale) * touch.x
            snapshot!.frame.origin.y = snapshot!.frame.origin.y * gesture.scale + (1-gesture.scale) * touch.y
            
            // reset the scale
            gesture.scale = 1.0
        case .Ended:
            let changedScale = snapshot!.frame.height / self.frame.height
            scale *= changedScale
            origin.x = origin.x * changedScale + snapshot!.frame.origin.x
            origin.y = origin.y * changedScale + snapshot!.frame.origin.y
            
            snapshot!.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    func move(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .Began:
            snapshot = snapshotViewAfterScreenUpdates(false)
            snapshot!.alpha = 0.8
            
            self.addSubview(snapshot!)
        case .Changed:
            let translation = gesture.translationInView(self)
            snapshot!.frame.origin.x += translation.x
            snapshot!.frame.origin.y += translation.y
            
            // reset it back to point zero in it's current view
            gesture.setTranslation(CGPointZero, inView: self)
        case .Ended:
            origin.x += snapshot!.frame.origin.x
            origin.y += snapshot!.frame.origin.y
            
            snapshot!.removeFromSuperview()
            snapshot = nil
        default: break
        }
    }
    
    func center(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .Ended:
            origin = gesture.locationInView(self)
        default: break
        }
    }
}
