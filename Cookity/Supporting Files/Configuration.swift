//
//  Configuration.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/12/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit


class Configuration {
    
    
    func configNumbers(quantity: String, measure: String) -> (Int, String) {
        
        var newQuantity: Int = 0
        var newMeasure = measure
        
        if measure.elementsEqual("l") || measure.elementsEqual("kg"){
            
            newQuantity = Int(Float(quantity)! * 1000)
            
            switch newMeasure {
                case "l":
                    newMeasure = "ml"
                default:
                    newMeasure = "g"
            }
            return (newQuantity, newMeasure)
        }
        else {
            newQuantity = Int(Float(quantity)!)
            return (newQuantity, newMeasure)
        }
    }
    
    
    func presentNumbers(quantity: Int, measure: String) -> (String, String) {
        
        var presentedMeasure = measure
        
        if quantity >= 1000 && presentedMeasure != "pcs" {
            let presentedQuantity = String(Float(quantity) / 1000)
            
            switch presentedMeasure {
            case "ml":
                presentedMeasure = "l"
            case "g":
                presentedMeasure = "kg"
            default:
                break
            }
            return (presentedQuantity, presentedMeasure)
        }
        else {
            let presentedQuantity = String(quantity)
            return (presentedQuantity, presentedMeasure)
        }
    }
    
    
    func configMeasure(measure: String) -> String {
        
        var savedMeasure = measure
        
        switch savedMeasure {
        case "Mililiters":
            savedMeasure = "ml"
        case "ml":
            savedMeasure = "Mililitres"
        case "Kilograms":
            savedMeasure = "kg"
        case "kg":
            savedMeasure = "Kilograms"
        case "Litres":
            savedMeasure = "l"
        case "l":
            savedMeasure = "Litres"
        case "Grams":
            savedMeasure = "g"
        case "g":
            savedMeasure = "Grams"
        case "Pieces":
            savedMeasure = "pcs"
        case "pcs":
            savedMeasure = "Pieces"
        default:
            savedMeasure = "pcs"
    }
        return savedMeasure
    }
}
