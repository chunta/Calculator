//
//  GraphViewController.swift
//  Calculator
//
//  Created by Xing Hui Lu on 10/12/15.
//  Copyright © 2015 Xing Hui Lu. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "zoom:"))
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: "move:"))
            let gesture = UITapGestureRecognizer(target: graphView, action: "center:")
            gesture.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(gesture)
        }
    }
    
    private var brain = CalculatorBrain()
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return brain.program
        }
        set {
            brain.program = newValue
        }
    }
    
    func y(x: CGFloat) -> CGFloat? {
        brain.variableValues["M"] = Double(x)
        if let y = brain.evaluate() {
            return CGFloat(y)
        }
        return nil
    }
}
