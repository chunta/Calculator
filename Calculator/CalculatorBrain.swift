//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Xing Hui Lu on 8/18/15.
//  Copyright (c) 2015 Xing Hui Lu. All rights reserved.
//

import Foundation

class CalculatorBrain: CustomStringConvertible {
    private var opStack = [Op]()
    private var knownSymbols = [String:Op]()
    private var constantValues = [String:Double]()
    var variableValues = [String:Double]()
    
    var description: String {
        get {
            var (result,ops) = ("", opStack)
            
            repeat {
                var current: String?
                (current,ops,_) = description(ops)
                result = result == "" ? current! : "\(current!), \(result)"
            } while ops.count > 0
            
            return result
        }
    }
    
    //program will always be a property list
    typealias PropertyList = AnyObject
    var program: PropertyList {
        get {
            return opStack.map { $0.description }
        }
        set {
            if let opSymbols = newValue as? [String] {
                var newOpStack = [Op]()
                for opSymbol in opSymbols {
                    if let op = knownSymbols[opSymbol] {
                        newOpStack.append(op)
                    } else if let operand = NSNumberFormatter().numberFromString(opSymbol)?.doubleValue {
                        newOpStack.append(.Operand(operand))
                    } else {
                        newOpStack.append(.Variable(opSymbol))
                    }
                }
                opStack = newOpStack
            }
        }
    }
    
    private enum Op: CustomStringConvertible {
        case Operand(Double)
        case Variable(String)
        case Constant(String)
        case UnaryOperator(String, Double -> Double)
        case BinaryOperator(String, Int ,(Double, Double) -> Double)
        
        var description: String {
            switch self {
            case .Operand(let operand):
                return "\(operand)"
            case .Constant(let symbol):
                return symbol
            case .UnaryOperator(let symbol, _):
                return symbol
            case .BinaryOperator(let symbol,_,_):
                return symbol
            case .Variable(let symbol):
                return symbol
            }
        }
        
        var precedence: Int {
            get {
                switch self {
                case .BinaryOperator(_, let precedence,_):
                    return precedence
                default:
                    return Int.max
                }
            }
        }
    }
    
    
    init() {
        constantValues["π"] = M_PI
        
        func learnOp(op: Op) {
            knownSymbols[op.description] = op
        }
        
        learnOp(Op.Constant("π"))
        learnOp(Op.BinaryOperator("÷", 2){ $1 / $0 })
        learnOp(Op.BinaryOperator("×", 2, *))
        learnOp(Op.BinaryOperator("+", 1, +))
        learnOp(Op.BinaryOperator("−", 1) { $1 - $0 })
        learnOp(Op.UnaryOperator("√", sqrt))
        learnOp(Op.UnaryOperator("sin", sin))
        learnOp(Op.UnaryOperator("cos", cos))
        learnOp(Op.UnaryOperator("tan", tan))
        learnOp(Op.UnaryOperator("ᐩ/-") { -($0) })
    }
    
    
    func pushOperand(operand: Double) -> Double? {
        opStack.append(Op.Operand(operand))
        return evaluate()
    }
    
    
    func pushOperand(symbol: String) -> Double? {
        opStack.append(Op.Variable(symbol))
        return evaluate()
    }
    
    
    func performOperation(symbol: String) -> Double? {
        if let op = knownSymbols[symbol] {
            opStack.append(op)
        }
        return evaluate()
    }
    
    
    private func evaluate(ops: [Op]) -> (result: Double?, remainingOps: [Op]) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            
            switch op {
            case .Operand(let operand):
                return (operand, remainingOps)
            case .Constant(let symbol):
                return (constantValues[symbol], remainingOps)
            case .UnaryOperator(_, let operation):
                let operandEvaluation = evaluate(remainingOps)
                if let operand = operandEvaluation.result {
                    return (operation(operand), operandEvaluation.remainingOps)
                }
            case .BinaryOperator(_,_,let operation):
                let op1Evaluation = evaluate(remainingOps)
                if let operand1 = op1Evaluation.result {
                    let op2Evaluation = evaluate(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return (operation(operand1, operand2), op2Evaluation.remainingOps)
                    }
                }
            case .Variable(let symbol):
                if let value = variableValues[symbol] {
                    return (value, remainingOps)
                }
            }
        }
        
        return (nil, ops)
    }
    
    
    func evaluate() -> Double? {
        let (result, remainder)  = evaluate(opStack)
        print("\(opStack) = \(result) with remainder \(remainder) left over" )
        
        return result
    }
    
    
    private func description(ops: [Op]) -> (result: String?, remainingOps: [Op], precedence: Int?) {
        if !ops.isEmpty {
            var remainingOps = ops
            let op = remainingOps.removeLast()
            switch op {
            case .Operand(let operand):
                return ("\(operand)", remainingOps, op.precedence)
            case .Constant(let symbol):
                return (symbol, remainingOps, op.precedence)
            case .Variable(let symbol):
                return (symbol, remainingOps, op.precedence)
            case .UnaryOperator(let symbol,_):
                let operandDescription = description(remainingOps)
                if let operand = operandDescription.result {
                    return ("\(symbol)(\(operand))", operandDescription.remainingOps, op.precedence)
                }
            case .BinaryOperator(let symbol,_,_):
                let op1Evaluation = description(remainingOps)
                if var operand1 = op1Evaluation.result {
                    if op.precedence > op1Evaluation.precedence {
                        operand1 = "(\(operand1))"
                    }
                    let op2Evaluation = description(op1Evaluation.remainingOps)
                    if let operand2 = op2Evaluation.result {
                        return ("\(operand2)\(symbol)\(operand1)", op2Evaluation.remainingOps, op.precedence)
                    }
                }
            }
        }
        return ("", ops, Int.max)
    }
}