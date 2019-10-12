//
//  Configuration.swift
//  Cookity
//
//  Created by Mihails Kuznecovs on 04/12/2018.
//  Copyright © 2018 Mihails Kuznecovs. All rights reserved.
//

import UIKit
import RealmSwift

class Configuration {
    
    
    static func configNumbers(quantity: String, measure: String) -> (Int, String) {
        
        let quantity = quantity.replacingOccurrences(of: ",", with: ".")
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
    
    
    static func presentNumbers(quantity: Int, measure: String) -> (String, String) {
        
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
    
    
    static func configMeasure(measure: String) -> String {
        
        var savedMeasure = measure

        switch savedMeasure {
        case "Mililiters":
            savedMeasure = "ml"
        case "ml":
            savedMeasure = "Mililiters"
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
    
    
    static func compareFridgeToRecipe(selectedProduct: Product, compareTo productList: [Product]) -> (Bool, Product?) {
            for product in productList{
                if selectedProduct.name.lowercased() == product.name.lowercased(){
                    return (true, product)
                }
            }
        return (false, nil)
    }
    
//    static func configureViewController(ofType vc: UIViewController?, parentObject: Object?) {
//        
//        if let vc = vc as? CookViewController, let recipe = parentObject as? Recipe {
//            for product in recipe.products {
//                let product = Product(value: product)
//                vc.products.append(product)
//            }
//            for recipeStep in recipe.recipeSteps {
//                let recipeStep = RecipeStep(value: recipeStep)
//                if vc.recipeSteps?.append(recipeStep) == nil {
//                    vc.recipeSteps = [recipeStep]
//                }
//            }
//            if let imageFileName = recipe.imageFileName,
//                let image = getImageFromFileManager(with: imageFileName) {
//                vc.pickedImage = image
//            }
//        }
//        else if let vc = vc as? PopupEditViewController, let product = parentObject as? Product {
//            var (presentedQuantity, presentedMeasure) = Configuration.presentNumbers(quantity: product.quantity, measure: product.measure)
//            presentedMeasure = Configuration.configMeasure(measure: presentedMeasure)
//            vc.nameText.text = product.name
//            vc.quantityText.text = presentedQuantity
//            vc.measureText.text = presentedMeasure
//        }
//    }
    
    static func getImageFromFileManager(with imageFileName: String) -> UIImage? {
        let imagePath: String = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])/\(imageFileName)"
        let imageUrl: URL = URL(fileURLWithPath: imagePath)
        if FileManager.default.fileExists(atPath: imagePath),
            let imageData: Data = try? Data(contentsOf: imageUrl),
            let image: UIImage = UIImage(data: imageData) {
            return image
        }
        else {
            return nil
        }
    }
}
